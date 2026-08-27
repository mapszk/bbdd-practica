"use strict";

// Vista "Ver datos": navegar el contenido real de las tablas de una base
// (sin tener que escribir SELECT * a mano cada vez).
const Datos = (() => {
  let overlay, esquema, tablaActual, filas = [], total = 0;
  let limite = 100, offset = 0;

  const BASES = [
    { clave: "afatse", etiqueta: "afatse" },
    { clave: "agencia_personal", etiqueta: "agencia_personal" },
    { clave: "ropa_siempre_limpia", etiqueta: "ropa_siempre_limpia" },
  ];

  function crearOverlay() {
    overlay = document.createElement("div");
    overlay.id = "datos-overlay";
    Object.assign(overlay.style, {
      position: "fixed", inset: "0", background: "rgba(10,10,14,.92)", zIndex: 200,
      display: "flex", flexDirection: "column",
    });
    overlay.innerHTML = `
      <div style="display:flex;gap:10px;align-items:center;padding:10px 16px;background:#262832;border-bottom:1px solid #3a3d4a">
        <b>Datos cargados</b>
        <select id="datos-select-db"></select>
        <select id="datos-select-tabla"></select>
        <span id="datos-contador" style="color:#9497a8;font-size:12px"></span>
        <span style="flex:1"></span>
        <button id="datos-anterior">◀</button>
        <button id="datos-siguiente">▶</button>
        <button id="datos-cerrar">Cerrar ✕</button>
      </div>
      <div id="datos-cuerpo" style="flex:1;overflow:auto;padding:14px 20px"></div>
    `;
    document.body.appendChild(overlay);
    overlay.querySelector("#datos-select-db").innerHTML = BASES.map(
      (b) => `<option value="${b.clave}">${b.etiqueta}</option>`
    ).join("");
    overlay.querySelector("#datos-select-db").onchange = (e) => cargarEsquema(e.target.value);
    overlay.querySelector("#datos-select-tabla").onchange = (e) => cargarFilas(e.target.value, 0);
    overlay.querySelector("#datos-anterior").onclick = () => cargarFilas(tablaActual, Math.max(0, offset - limite));
    overlay.querySelector("#datos-siguiente").onclick = () => cargarFilas(tablaActual, offset + limite);
    overlay.querySelector("#datos-cerrar").onclick = cerrar;
  }

  async function abrir(dbInicial) {
    if (!overlay) crearOverlay();
    overlay.style.display = "flex";
    overlay.querySelector("#datos-select-db").value = dbInicial || "afatse";
    await cargarEsquema(dbInicial || "afatse");
  }

  function cerrar() {
    overlay.style.display = "none";
  }

  async function cargarEsquema(db) {
    esquema = await api("GET", `/api/esquema/${db}`);
    const select = overlay.querySelector("#datos-select-tabla");
    select.innerHTML = esquema.tablas.map((t) => `<option value="${t.nombre}">${t.nombre}</option>`).join("");
    if (esquema.tablas.length) await cargarFilas(esquema.tablas[0].nombre, 0);
  }

  async function cargarFilas(tabla, nuevoOffset) {
    tablaActual = tabla;
    offset = nuevoOffset;
    overlay.querySelector("#datos-select-tabla").value = tabla;
    const db = overlay.querySelector("#datos-select-db").value;
    const cuerpo = overlay.querySelector("#datos-cuerpo");
    cuerpo.innerHTML = "<div class='mensaje-ok'>Cargando...</div>";
    try {
      const r = await api("GET", `/api/esquema/${db}/${encodeURIComponent(tabla)}/filas?limite=${limite}&offset=${offset}`);
      filas = r.filas;
      total = r.total;
      render();
    } catch (e) {
      cuerpo.innerHTML = `<div class="mensaje-ok">Error al leer la tabla: ${escapeHtml(e.message)}</div>`;
    }
  }

  function render() {
    const cuerpo = overlay.querySelector("#datos-cuerpo");
    const desde = total ? offset + 1 : 0;
    const hasta = Math.min(offset + limite, total);
    overlay.querySelector("#datos-contador").textContent = `${desde}–${hasta} de ${total} filas`;
    overlay.querySelector("#datos-anterior").disabled = offset <= 0;
    overlay.querySelector("#datos-siguiente").disabled = offset + limite >= total;

    if (!filas.length) {
      cuerpo.innerHTML = "<div class='mensaje-ok'>Esta tabla no tiene filas cargadas.</div>";
      return;
    }
    const columnas = Object.keys(filas[0]);
    let html = `<table style="border-collapse:collapse;font-family:var(--mono);font-size:12.5px;white-space:nowrap">
      <thead><tr>${columnas.map((c) => `<th style="position:sticky;top:0;background:#2e303c;border:1px solid var(--borde);padding:4px 8px;text-align:left">${escapeHtml(c)}</th>`).join("")}</tr></thead>
      <tbody>`;
    for (const fila of filas) {
      html += `<tr>${columnas.map((c) => {
        const v = fila[c];
        return `<td style="border:1px solid var(--borde);padding:4px 8px;${v === null ? "color:var(--texto-tenue);font-style:italic" : ""}">${v === null ? "NULL" : escapeHtml(String(v))}</td>`;
      }).join("")}</tr>`;
    }
    html += "</tbody></table>";
    cuerpo.innerHTML = html;
  }

  return { abrir };
})();
