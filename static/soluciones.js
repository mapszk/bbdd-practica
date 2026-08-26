"use strict";

// Vista "Mis soluciones": todos los ejercicios resueltos (y no resueltos)
// con su SQL guardado, para repasar sin tener que ir abriendo mis_soluciones.sql.
const Soluciones = (() => {
  let overlay, datos = [];
  let filtro = "resueltos"; // "resueltos" | "todos"
  let busqueda = "";

  function crearOverlay() {
    overlay = document.createElement("div");
    overlay.id = "sol-overlay";
    Object.assign(overlay.style, {
      position: "fixed", inset: "0", background: "rgba(10,10,14,.92)", zIndex: 200,
      display: "flex", flexDirection: "column",
    });
    overlay.innerHTML = `
      <div style="display:flex;gap:10px;align-items:center;padding:10px 16px;background:#262832;border-bottom:1px solid #3a3d4a">
        <b>Mis soluciones</b>
        <div style="display:flex;gap:4px">
          <button id="sol-tab-resueltos">Resueltos</button>
          <button id="sol-tab-todos">Todos</button>
        </div>
        <input id="sol-buscar" placeholder="Buscar por consigna o SQL..." style="width:280px">
        <span id="sol-contador" style="color:#9497a8;font-size:12px"></span>
        <span style="flex:1"></span>
        <button id="sol-exportar">📄 Exportar mis_soluciones.sql</button>
        <button id="sol-cerrar">Cerrar ✕</button>
      </div>
      <div id="sol-cuerpo" style="flex:1;overflow:auto;padding:14px 20px"></div>
    `;
    document.body.appendChild(overlay);
    overlay.querySelector("#sol-tab-resueltos").onclick = () => { filtro = "resueltos"; render(); };
    overlay.querySelector("#sol-tab-todos").onclick = () => { filtro = "todos"; render(); };
    overlay.querySelector("#sol-buscar").oninput = (e) => { busqueda = e.target.value.toLowerCase(); render(); };
    overlay.querySelector("#sol-cerrar").onclick = cerrar;
    overlay.querySelector("#sol-exportar").onclick = async () => {
      const r = await api("POST", "/api/exportar");
      toast("Exportado: " + r.ruta);
    };
  }

  async function abrir() {
    if (!overlay) crearOverlay();
    overlay.style.display = "flex";
    datos = await api("GET", "/api/soluciones/detalle");
    render();
  }

  function cerrar() {
    overlay.style.display = "none";
  }

  const ETIQUETAS_ESTADO = {
    resuelto: "✓ resuelto", borrador: "✎ borrador", revisar: "⚑ revisar", sin_resolver: "sin resolver",
  };

  function render() {
    overlay.querySelector("#sol-tab-resueltos").classList.toggle("primario", filtro === "resueltos");
    overlay.querySelector("#sol-tab-todos").classList.toggle("primario", filtro === "todos");

    let lista = datos.filter((d) => (filtro === "todos" ? true : d.sql.trim() !== ""));
    if (busqueda) {
      lista = lista.filter(
        (d) => d.consigna.toLowerCase().includes(busqueda) || d.sql.toLowerCase().includes(busqueda)
      );
    }

    const cuerpo = overlay.querySelector("#sol-cuerpo");
    overlay.querySelector("#sol-contador").textContent =
      `${datos.filter((d) => d.sql.trim() !== "").length}/${datos.length} resueltos · mostrando ${lista.length}`;

    if (!lista.length) {
      cuerpo.innerHTML = "<div class='mensaje-ok'>No hay ejercicios que coincidan.</div>";
      return;
    }

    let html = "";
    for (const d of lista) {
      const claseEstado = d.estado === "resuelto" ? "coincide" : d.estado === "revisar" ? "difiere" : "no_comparable";
      html += `<div class="sol-item" data-id="${d.id}" style="margin-bottom:14px;border:1px solid var(--borde);border-radius:8px;overflow:hidden">
        <div style="display:flex;align-items:center;gap:10px;padding:8px 12px;background:var(--bg-panel-2);cursor:pointer" class="sol-header">
          <b>P${d.practica_numero}.${d.ejercicio_numero}</b>
          <span class="veredicto ${claseEstado}" style="margin:0">${ETIQUETAS_ESTADO[d.estado] || d.estado}</span>
          <span style="color:var(--texto-tenue);font-size:12px;flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(d.consigna || "(sin consigna)")}</span>
          <button class="sol-ir" data-p="${d.practica_numero}" data-e="${d.ejercicio_numero}">Ir al ejercicio →</button>
        </div>
        <pre class="sol-sql" style="margin:0;padding:10px 12px;font-family:var(--mono);font-size:12.5px;white-space:pre-wrap;background:#16171d;${d.sql.trim() ? "" : "color:var(--texto-tenue);font-style:italic"}">${escapeHtml(d.sql.trim() || "(sin resolver)")}</pre>
        ${d.solucion_ideal ? `
        <div style="padding:2px 12px 4px;font-size:11px;color:var(--verde);background:#16171d">Solución ideal</div>
        <pre class="sol-sql" style="margin:0;padding:6px 12px 10px;font-family:var(--mono);font-size:12.5px;white-space:pre-wrap;background:#16171d;border-top:1px dashed var(--borde)">${escapeHtml(d.solucion_ideal)}</pre>
        ` : ""}
      </div>`;
    }
    cuerpo.innerHTML = html;

    cuerpo.querySelectorAll(".sol-ir").forEach((btn) => {
      btn.onclick = async (ev) => {
        ev.stopPropagation();
        cerrar();
        await irA(parseInt(btn.dataset.p, 10), parseInt(btn.dataset.e, 10));
      };
    });
  }

  return { abrir };
})();
