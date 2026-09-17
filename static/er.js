"use strict";

const ER = (() => {
  let overlay, svg, datosEsquema, posiciones, dbActual;
  let vista = "mapa"; // "mapa" | "texto"
  let pan = { x: 40, y: 40, k: 1 };
  let arrastrando = null;

  // Standalone = esta página no es la app completa (es esquema.html en su
  // propia pestaña), así que no tiene sentido un botón "Cerrar" (no hay a
  // qué volver) ni uno de "abrir en pestaña" (ya está en una).
  const STANDALONE = !!window.__ER_STANDALONE__;

  // toast() vive en app.js -- en la pestaña standalone no está cargado, así
  // que armamos un reemplazo mínimo con el mismo aspecto.
  function avisar(msg, ms = 3000) {
    if (typeof window.toast === "function") return window.toast(msg, ms);
    const el = document.createElement("div");
    el.className = "toast";
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), ms);
  }

  const BASES = [
    { clave: "afatse", etiqueta: "afatse" },
    { clave: "agencia_personal", etiqueta: "agencia_personal" },
    { clave: "ropa_siempre_limpia", etiqueta: "ropa_siempre_limpia" },
    { clave: "parcial", etiqueta: "parcial" },
  ];

  function crearOverlay() {
    overlay = document.createElement("div");
    overlay.id = "er-overlay";
    Object.assign(overlay.style, {
      position: "fixed", inset: "0", background: STANDALONE ? "var(--bg, #1e1f26)" : "rgba(10,10,14,.92)",
      zIndex: 200, display: "flex", flexDirection: "column",
    });
    overlay.innerHTML = `
      <div style="display:flex;gap:10px;align-items:center;padding:10px 16px;background:#262832;border-bottom:1px solid #3a3d4a">
        <b>Esquema de la base</b>
        <select id="er-select-db"></select>
        <div style="display:flex;gap:4px">
          <button id="er-tab-mapa">Mapa</button>
          <button id="er-tab-texto">Texto</button>
        </div>
        <label style="font-size:12px;color:#9497a8"><input type="checkbox" id="er-chk-inferidas" checked> mostrar inferidas</label>
        <button id="er-copiar-mermaid">Copiar Mermaid</button>
        <span style="flex:1"></span>
        ${STANDALONE ? "" : '<button id="er-abrir-pestana">🗗 Abrir en otra pestaña</button>'}
        ${STANDALONE ? "" : '<button id="er-cerrar">Cerrar ✕</button>'}
      </div>
      <div id="er-cuerpo" style="flex:1;overflow:auto;position:relative"></div>
    `;
    document.body.appendChild(overlay);
    overlay.querySelector("#er-select-db").innerHTML = BASES.map(
      (b) => `<option value="${b.clave}">${b.etiqueta}</option>`
    ).join("");
    overlay.querySelector("#er-select-db").onchange = (e) => cargar(e.target.value);
    overlay.querySelector("#er-tab-mapa").onclick = () => { vista = "mapa"; render(); };
    overlay.querySelector("#er-tab-texto").onclick = () => { vista = "texto"; render(); };
    overlay.querySelector("#er-chk-inferidas").onchange = render;
    overlay.querySelector("#er-copiar-mermaid").onclick = copiarMermaid;
    if (!STANDALONE) {
      overlay.querySelector("#er-cerrar").onclick = cerrar;
      overlay.querySelector("#er-abrir-pestana").onclick = () => {
        window.open(`/static/esquema.html?db=${encodeURIComponent(dbActual)}`, "_blank");
      };
    }
  }

  async function abrir(dbInicial) {
    if (!overlay) crearOverlay();
    overlay.style.display = "flex";
    overlay.querySelector("#er-select-db").value = dbInicial || "afatse";
    await cargar(dbInicial || "afatse");
  }

  function cerrar() {
    overlay.style.display = "none";
  }

  async function cargar(db) {
    dbActual = db;
    if (STANDALONE) document.title = `Esquema · ${db}`;
    const resp = await fetch(`/api/esquema/${db}`);
    datosEsquema = await resp.json();
    let layout = {};
    try {
      layout = await (await fetch(`/api/esquema/${db}/layout`)).json();
    } catch (e) {}
    posiciones = layout.posiciones || calcularLayoutInicial(datosEsquema);
    pan = layout.pan || { x: 40, y: 40, k: 1 };
    render();
  }

  function calcularLayoutInicial(esquema) {
    const nombres = esquema.tablas.map((t) => t.nombre);
    const nivel = Object.fromEntries(nombres.map((n) => [n, 0]));
    for (let iter = 0; iter < nombres.length; iter++) {
      for (const fk of esquema.fks) {
        if (fk.tabla === fk.tabla_ref) continue;
        nivel[fk.tabla] = Math.max(nivel[fk.tabla] ?? 0, (nivel[fk.tabla_ref] ?? 0) + 1);
      }
    }
    const porNivel = {};
    for (const n of nombres) (porNivel[nivel[n]] ??= []).push(n);
    const pos = {};
    Object.keys(porNivel).sort((a, b) => a - b).forEach((lvl, li) => {
      porNivel[lvl].forEach((nombre, i) => {
        pos[nombre] = { x: li * 260 + 20, y: i * 140 + 20 };
      });
    });
    return pos;
  }

  function render() {
    const cuerpo = overlay.querySelector("#er-cuerpo");
    overlay.querySelector("#er-tab-mapa").classList.toggle("primario", vista === "mapa");
    overlay.querySelector("#er-tab-texto").classList.toggle("primario", vista === "texto");
    if (vista === "texto") renderTexto(cuerpo);
    else renderMapa(cuerpo);
  }

  function renderTexto(cuerpo) {
    const referenciadaPor = {};
    for (const fk of datosEsquema.fks) {
      (referenciadaPor[fk.tabla_ref] ??= []).push(`${fk.tabla}(${fk.columnas.join(", ")})`);
    }
    let html = `<div style="padding:14px;color:#e4e6f0;font-family:monospace;font-size:13px">`;
    html += `<input id="er-buscar" placeholder="Buscar tabla o columna..." style="margin-bottom:10px;width:300px">`;
    for (const t of datosEsquema.tablas) {
      const refsPropias = datosEsquema.fks.filter((f) => f.tabla === t.nombre);
      html += `<div class="er-tabla-texto" data-buscar="${t.nombre.toLowerCase()} ${t.columnas.map(c=>c.nombre).join(" ").toLowerCase()}" style="margin-bottom:14px;border:1px solid #3a3d4a;border-radius:6px;padding:10px">`;
      html += `<div style="font-weight:600;color:#5b8def">${t.nombre}</div>`;
      for (const c of t.columnas) {
        html += `<div>${c.pk ? "🔑 " : "&nbsp;&nbsp;&nbsp;"}${c.nombre} <span style="color:#9497a8">${c.tipo}</span></div>`;
      }
      if (refsPropias.length) {
        html += `<div style="margin-top:6px;color:#9497a8">referencia a: ${refsPropias.map(f => `${f.tabla_ref}(${f.columnas_ref.join(", ")})`).join(" · ")}</div>`;
      }
      if (referenciadaPor[t.nombre]) {
        html += `<div style="color:#9497a8">referenciada por: ${referenciadaPor[t.nombre].join(" · ")}</div>`;
      }
      html += `</div>`;
    }
    if (datosEsquema.vistas?.length) html += `<div>Vistas: ${datosEsquema.vistas.join(", ")}</div>`;
    if (datosEsquema.triggers?.length) html += `<div>Triggers: ${datosEsquema.triggers.map(t=>t.nombre).join(", ")}</div>`;
    if (datosEsquema.rutinas?.length) html += `<div>Rutinas: ${datosEsquema.rutinas.map(r=>r.nombre).join(", ")}</div>`;
    html += `</div>`;
    cuerpo.innerHTML = html;
    cuerpo.querySelector("#er-buscar").oninput = (e) => {
      const q = e.target.value.toLowerCase();
      cuerpo.querySelectorAll(".er-tabla-texto").forEach((el) => {
        el.style.display = el.dataset.buscar.includes(q) ? "" : "none";
      });
    };
  }

  function centroDe(nombre) {
    const p = posiciones[nombre] || { x: 0, y: 0 };
    return { x: p.x + 100, y: p.y + 30 };
  }

  function renderMapa(cuerpo) {
    const mostrarInferidas = overlay.querySelector("#er-chk-inferidas").checked;
    cuerpo.innerHTML = `<svg id="er-svg" width="100%" height="100%" style="cursor:grab;background:#16171d;user-select:none;-webkit-user-select:none">
      <g id="er-g"></g>
    </svg>`;
    svg = cuerpo.querySelector("#er-svg");
    const g = cuerpo.querySelector("#er-g");

    let inner = "";
    const fks = [...datosEsquema.fks.map((f) => ({ ...f, inferida: false }))];
    if (mostrarInferidas) fks.push(...datosEsquema.fks_inferidas.map((f) => ({ ...f, inferida: true })));

    for (const fk of fks) {
      const a = centroDe(fk.tabla), b = centroDe(fk.tabla_ref);
      const punteado = fk.inferida ? ' stroke-dasharray="6,4"' : "";
      const color = fk.inferida ? "#6b6e7d" : "#5b8def";
      const mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
      inner += `<g class="er-edge" data-tabla="${fk.tabla}" data-ref="${fk.tabla_ref}">
        <line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" stroke="${color}" stroke-width="1.5"${punteado} />
        <text x="${mx}" y="${my}" fill="${color}" font-size="10" style="user-select:none;pointer-events:none">${fk.columnas.join(",")}</text>
      </g>`;
    }

    for (const t of datosEsquema.tablas) {
      const p = posiciones[t.nombre] || { x: 0, y: 0 };
      const h = 26 + t.columnas.length * 16;
      inner += `<g class="er-nodo" data-tabla="${t.nombre}" transform="translate(${p.x},${p.y})" style="cursor:move;user-select:none;-webkit-user-select:none">
        <rect width="200" height="${h}" rx="6" fill="#262832" stroke="#3a3d4a"/>
        <rect width="200" height="24" rx="6" fill="#2e303c"/>
        <text x="10" y="17" fill="#5b8def" font-size="13" font-weight="600" style="user-select:none;pointer-events:none">${t.nombre}</text>`;
      t.columnas.forEach((c, i) => {
        inner += `<text x="10" y="${40 + i * 16}" fill="${c.pk ? "#e0a63c" : "#e4e6f0"}" font-size="11" style="user-select:none;pointer-events:none">${c.pk ? "🔑 " : ""}${c.nombre}</text>`;
      });
      inner += `</g>`;
    }

    g.innerHTML = inner;
    aplicarTransform();
    habilitarInteraccion(g);
  }

  function moverNodoEnDom(tabla) {
    const g = overlay.querySelector("#er-g");
    if (!g) return;
    const nodo = g.querySelector(`.er-nodo[data-tabla="${CSS.escape(tabla)}"]`);
    const p = posiciones[tabla];
    if (nodo && p) nodo.setAttribute("transform", `translate(${p.x},${p.y})`);

    g.querySelectorAll(`.er-edge[data-tabla="${CSS.escape(tabla)}"], .er-edge[data-ref="${CSS.escape(tabla)}"]`)
      .forEach((edge) => {
        const a = centroDe(edge.dataset.tabla), b = centroDe(edge.dataset.ref);
        const linea = edge.querySelector("line");
        const texto = edge.querySelector("text");
        linea.setAttribute("x1", a.x); linea.setAttribute("y1", a.y);
        linea.setAttribute("x2", b.x); linea.setAttribute("y2", b.y);
        texto.setAttribute("x", (a.x + b.x) / 2); texto.setAttribute("y", (a.y + b.y) / 2);
      });
  }

  function aplicarTransform() {
    const g = overlay.querySelector("#er-g");
    if (g) g.setAttribute("transform", `translate(${pan.x},${pan.y}) scale(${pan.k})`);
  }

  // Estado de interacción a nivel de módulo -- NO closures locales a
  // habilitarInteraccion(): antes vivían como `let` dentro de la función y
  // como el arrastre llamaba a render() en cada mousemove, se recreaba
  // habilitarInteraccion() (y con ella "ultimo"/"panActivo" en null) en
  // pleno arrastre, así que el nodo se movía un pixel y quedaba congelado.
  let panActivo = false;
  let ultimoMouse = null;

  function habilitarInteraccion(g) {
    svg.onwheel = (ev) => {
      ev.preventDefault();
      const factor = ev.deltaY < 0 ? 1.1 : 0.9;
      pan.k = Math.min(3, Math.max(0.3, pan.k * factor));
      aplicarTransform();
      guardarLayoutDebounced();
    };

    svg.onmousedown = (ev) => {
      ev.preventDefault(); // evita que el navegador arranque una selección de texto
      const nodo = ev.target.closest(".er-nodo");
      if (nodo) {
        arrastrando = nodo.dataset.tabla;
      } else {
        panActivo = true;
      }
      ultimoMouse = { x: ev.clientX, y: ev.clientY };
    };
    window.onmousemove = (ev) => {
      if (!ultimoMouse) return;
      const dx = ev.clientX - ultimoMouse.x, dy = ev.clientY - ultimoMouse.y;
      ultimoMouse = { x: ev.clientX, y: ev.clientY };
      if (arrastrando) {
        const p = posiciones[arrastrando];
        p.x += dx / pan.k; p.y += dy / pan.k;
        moverNodoEnDom(arrastrando); // actualiza sólo ese nodo/aristas, sin re-render completo
      } else if (panActivo) {
        pan.x += dx; pan.y += dy;
        aplicarTransform();
      }
    };
    window.onmouseup = () => {
      if (arrastrando || panActivo) guardarLayoutDebounced();
      arrastrando = null; panActivo = false; ultimoMouse = null;
    };
  }

  let guardarTimer = null;
  function guardarLayoutDebounced() {
    clearTimeout(guardarTimer);
    guardarTimer = setTimeout(() => {
      fetch(`/api/esquema/${dbActual}/layout`, {
        method: "PUT", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ posiciones, pan }),
      });
    }, 500);
  }

  async function copiarMermaid() {
    const resp = await fetch(`/api/esquema/${dbActual}/mermaid`);
    const datos = await resp.json();
    try {
      await navigator.clipboard.writeText(datos.mermaid);
      avisar("Diagrama Mermaid copiado al portapapeles");
    } catch (e) {
      alert(datos.mermaid);
    }
  }

  return { abrir };
})();
