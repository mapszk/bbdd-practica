"use strict";

const estado = {
  practicas: [],
  actual: { p: 1, e: 1 },
  sesionActiva: "principal",
  tab: "resultado",
  ultimoResultado: null,
  ultimaComparacion: null,
  editor: null,
  usaCodeMirror: false,
  guardando: null,
};

async function api(metodo, ruta, cuerpo) {
  const opts = { method: metodo, headers: {} };
  if (cuerpo !== undefined) {
    opts.headers["Content-Type"] = "application/json";
    opts.body = JSON.stringify(cuerpo);
  }
  const resp = await fetch(ruta, opts);
  if (!resp.ok) {
    const texto = await resp.text().catch(() => resp.statusText);
    throw new Error(`${resp.status}: ${texto}`);
  }
  return resp.json();
}

function toast(msg, ms = 3000) {
  const el = document.createElement("div");
  el.className = "toast";
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), ms);
}

// ------------------------------------------------------------------ //
// Editor
// ------------------------------------------------------------------ //
function initEditor() {
  const caja = document.getElementById("editor-caja");
  if (window.CodeMirror) {
    try {
      const fallback = document.getElementById("editor-fallback");
      estado.editor = CodeMirror(caja, {
        value: "",
        mode: "text/x-mysql",
        theme: "dracula",
        lineNumbers: true,
        matchBrackets: true,
        autoCloseBrackets: true,
        styleActiveLine: true,
        indentUnit: 2,
        extraKeys: {
          "Ctrl-Space": "autocomplete",
          "Ctrl-Enter": ejecutar,
        },
      });
      fallback.remove();
      estado.usaCodeMirror = true;
    } catch (e) {
      console.error("Fallo CodeMirror, uso textarea", e);
    }
  }
  if (!estado.usaCodeMirror) {
    toast("No se pudo cargar el editor avanzado, usando texto simple.");
  }
}

function getSql() {
  return estado.usaCodeMirror ? estado.editor.getValue() : document.getElementById("editor-fallback").value;
}
function setSql(v) {
  if (estado.usaCodeMirror) estado.editor.setValue(v || "");
  else document.getElementById("editor-fallback").value = v || "";
}

// ------------------------------------------------------------------ //
// Riel de prácticas
// ------------------------------------------------------------------ //
let solucionesCache = {};

async function cargarRiel() {
  estado.practicas = await api("GET", "/api/practicas");
  const sol = await api("GET", "/api/soluciones");
  solucionesCache = sol.soluciones || {};
  renderRiel();
}

function estadoPunto(id) {
  const s = solucionesCache[id];
  if (!s) return "";
  return s.estado || "";
}

const ETIQUETAS_CHIP_ESTADO = {
  resuelto: "✓ Resuelto", revisar: "✗ A revisar", borrador: "✎ Borrador",
};
function chipEstadoHtml(id) {
  const clase = estadoPunto(id) || "sin-empezar";
  const etiqueta = ETIQUETAS_CHIP_ESTADO[clase] || "Sin empezar";
  return `<span class="chip-estado ${clase}">${etiqueta}</span>`;
}

function renderRiel() {
  const riel = document.getElementById("riel");
  riel.innerHTML = "";
  let separadorPuesto = false;
  for (const p of estado.practicas) {
    const esParcial = p.titulo.startsWith("Parcial");
    if (esParcial && !separadorPuesto) {
      const separador = document.createElement("div");
      separador.className = "riel-separador";
      separador.textContent = "Repaso -- Parcial";
      riel.appendChild(separador);
      separadorPuesto = true;
    }

    const grupo = document.createElement("div");
    grupo.className = "practica-grupo";
    const titulo = document.createElement("div");
    titulo.className = "practica-titulo";
    const tema = esParcial ? p.titulo.split(":")[1]?.trim() : null;
    titulo.textContent = tema || (esParcial ? "Parcial" : `P${p.numero}`);
    titulo.title = p.titulo;
    grupo.appendChild(titulo);

    const puntos = document.createElement("div");
    puntos.className = "ejercicios-puntos";
    p.ids.forEach((id, idx) => {
      const n = idx + 1;
      const btn = document.createElement("div");
      const cls = estadoPunto(id);
      btn.className = "punto" + (cls ? " " + cls : "");
      if (p.numero === estado.actual.p && n === estado.actual.e) btn.classList.add("activo");
      btn.textContent = n;
      btn.title = id;
      btn.onclick = () => irA(p.numero, n);
      puntos.appendChild(btn);
    });
    grupo.appendChild(puntos);
    riel.appendChild(grupo);
  }

  const acciones = document.createElement("div");
  acciones.className = "riel-acciones";
  const btnEsquema = document.createElement("button");
  btnEsquema.textContent = "🗺 Ver esquema / relaciones";
  btnEsquema.onclick = () => ER.abrir(mapNombreBase(ejercicioActual ? ejercicioActual.base_datos : "afatse"));
  const btnSoluciones = document.createElement("button");
  btnSoluciones.textContent = "📋 Ver soluciones";
  btnSoluciones.onclick = () => Soluciones.abrir();
  const btnDatos = document.createElement("button");
  btnDatos.textContent = "🗄 Ver datos";
  btnDatos.onclick = () => Datos.abrir(mapNombreBase(ejercicioActual ? ejercicioActual.base_datos : "afatse"));
  const btnExportar = document.createElement("button");
  btnExportar.textContent = "📄 Exportar mis_soluciones.sql";
  btnExportar.onclick = async () => {
    const r = await api("POST", "/api/exportar");
    toast("Exportado: " + r.ruta);
  };
  acciones.appendChild(btnEsquema);
  acciones.appendChild(btnDatos);
  acciones.appendChild(btnSoluciones);
  acciones.appendChild(btnExportar);
  riel.appendChild(acciones);
}

// ------------------------------------------------------------------ //
// Navegación
// ------------------------------------------------------------------ //
function practicaActualObj() {
  return estado.practicas.find((p) => p.numero === estado.actual.p);
}

async function irA(p, e) {
  await guardarBorradorSiHaceFalta();
  estado.actual = { p, e };
  await cargarEjercicio();
  renderRiel();
}

async function siguiente() {
  const prac = practicaActualObj();
  if (!prac) return;
  if (estado.actual.e < prac.cantidad) {
    await irA(estado.actual.p, estado.actual.e + 1);
  } else {
    const idx = estado.practicas.findIndex((x) => x.numero === estado.actual.p);
    if (idx < estado.practicas.length - 1) {
      await irA(estado.practicas[idx + 1].numero, 1);
    }
  }
}

async function anterior() {
  if (estado.actual.e > 1) {
    await irA(estado.actual.p, estado.actual.e - 1);
  } else {
    const idx = estado.practicas.findIndex((x) => x.numero === estado.actual.p);
    if (idx > 0) {
      const prevPrac = estado.practicas[idx - 1];
      await irA(prevPrac.numero, prevPrac.cantidad);
    }
  }
}

// ------------------------------------------------------------------ //
// Cargar / renderizar ejercicio
// ------------------------------------------------------------------ //
let ejercicioActual = null;

async function cargarEjercicio() {
  const { p, e } = estado.actual;
  ejercicioActual = await api("GET", `/api/ejercicio/${p}/${e}`);
  renderConsigna();
  setSql(ejercicioActual.solucion ? ejercicioActual.solucion.sql : "");
  limpiarResultados();
  restaurarBannerEstado();
  document.getElementById("footer-info").textContent =
    `Práctica ${p} · Ejercicio ${e} de ${ejercicioActual.total_en_practica}`;
  await refrescarEstadoBd();
  await cargarHintsAutocompletado();
}

let hintsCache = {};
async function cargarHintsAutocompletado() {
  if (!estado.usaCodeMirror || !ejercicioActual.base_datos) return;
  const claveBd = mapNombreBase(ejercicioActual.base_datos);
  if (!hintsCache[claveBd]) {
    try {
      hintsCache[claveBd] = await api("GET", `/api/esquema/${claveBd}/hints`);
    } catch (e) { return; }
  }
  estado.editor.setOption("hintOptions", { tables: hintsCache[claveBd] });
}

function escapeHtml(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c]));
}

function renderTablaDoc(tabla) {
  if (!tabla || !tabla.filas || !tabla.filas.length) return "";
  const [encab, ...filas] = tabla.filas;
  let html = `<table class="tabla-doc"><thead><tr>${encab.map((c) => `<th>${escapeHtml(c)}</th>`).join("")}</tr></thead><tbody>`;
  for (const f of filas) {
    html += `<tr>${f.map((c) => `<td>${escapeHtml(c)}</td>`).join("")}</tr>`;
  }
  html += "</tbody></table>";
  return html;
}

function renderConsigna() {
  const ej = ejercicioActual;
  const panel = document.getElementById("panel-consigna");
  let html = "";
  html += `<div class="meta-ejercicio">Práctica ${ej.numero !== undefined ? estado.actual.p : ""} · ${escapeHtml(ej.practica_titulo)} ${ej.base_datos ? "· BD: " + escapeHtml(ej.base_datos) : ""}</div>`;
  html += `<h2>Ejercicio ${ej.numero} ${chipEstadoHtml(ej.id)}</h2>`;

  if (ej.flags && ej.flags.error_en_salida) {
    html += `<div class="badge aviso">⚠ El propio documento marca esta salida esperada como errónea</div>`;
  }
  if (ej.flags && ej.flags.fecha_dinamica) {
    html += `<div class="badge aviso">⚠ Este ejercicio calcula una fecha en base al día de hoy (CURDATE()): la columna de fecha nunca va a coincidir exactamente con la tabla esperada salvo que lo corras el mismo día en que se generó. Revisá el resto de las columnas para saber si tu consulta está bien.</div>`;
  }
  if (ej.seccion) {
    html += `<div class="badge aviso">${escapeHtml(ej.seccion)}</div>`;
  }

  html += `<div class="consigna-texto">${escapeHtml(ej.consigna || "(sin consigna -- ver sub-pasos)")}</div>`;

  if (ej.subpasos && ej.subpasos.length) {
    html += "<ol class='subpasos' type='a'>" + ej.subpasos.map((s) => `<li>${escapeHtml(s.texto)}</li>`).join("") + "</ol>";
  }

  for (const t of ej.tablas || []) {
    if (t.tipo === "resultado") continue; // se muestra en la solapa Esperado
    const etiqueta = { describe: "Estructura (DESCRIBE)", encabezados: "Encabezados sugeridos", entrada: "Datos de entrada" }[t.tipo] || t.tipo;
    html += `<div style="font-size:12px;color:var(--texto-tenue);margin-bottom:4px">${etiqueta}</div>`;
    html += renderTablaDoc(t);
  }

  if (ej.ayuda) {
    html += `<div class="badge ayuda" id="toggle-ayuda">💡 Mostrar ayuda</div><div class="ayuda-caja" id="caja-ayuda">${escapeHtml(ej.ayuda)}</div>`;
  }

  panel.innerHTML = html;

  const toggle = document.getElementById("toggle-ayuda");
  if (toggle) {
    toggle.onclick = () => document.getElementById("caja-ayuda").classList.toggle("visible");
  }

  renderAvisoModificada();
}

let bdEstadoCache = {};
async function refrescarEstadoBd() {
  try {
    bdEstadoCache = await api("GET", "/api/bd/estado");
  } catch (e) { /* silencioso */ }
  renderAvisoModificada();
}

function renderAvisoModificada() {
  const ej = ejercicioActual;
  if (!ej || !ej.base_datos) return;
  const claveBd = mapNombreBase(ej.base_datos);
  const info = bdEstadoCache[claveBd];
  const panel = document.getElementById("panel-consigna");
  const previo = panel.querySelector(".aviso-modifica");
  if (previo) previo.remove();
  if (info && info.modificada) {
    const aviso = document.createElement("div");
    aviso.className = "aviso-modifica";
    aviso.innerHTML = `<span>⚠ La base <b>${claveBd}</b> tiene datos modificados.</span>`;
    const btn = document.createElement("button");
    btn.textContent = `Reiniciar ${claveBd}`;
    btn.onclick = async () => {
      if (!confirm(`¿Reiniciar ${claveBd} desde el dump original? Se pierden los cambios.`)) return;
      await api("POST", "/api/bd/reiniciar", { db: claveBd });
      toast(`${claveBd} reiniciada`);
      await refrescarEstadoBd();
    };
    aviso.appendChild(btn);
    panel.insertBefore(aviso, panel.firstChild.nextSibling);
  }
}

function mapNombreBase(nombreDocx) {
  const n = (nombreDocx || "").toLowerCase();
  if (n.includes("afatse")) return "afatse";
  if (n.includes("agencia")) return "agencia_personal";
  if (n.includes("tintor") || n.includes("ropa")) return "ropa_siempre_limpia";
  if (n.includes("parcial") || n.includes("jusenkyo")) return "parcial";
  return n;
}

// ------------------------------------------------------------------ //
// Ejecución
// ------------------------------------------------------------------ //
function limpiarResultados() {
  estado.ultimoResultado = null;
  estado.ultimaComparacion = null;
  document.getElementById("panel-resultados").innerHTML = "<div class='mensaje-ok'>Ejecutá con Ctrl+Enter.</div>";
}

async function ejecutar() {
  const sql = getSql();
  if (!sql.trim()) return;
  document.getElementById("btn-ejecutar").disabled = true;
  document.getElementById("btn-cancelar").disabled = false;
  try {
    const dbObjetivo = ejercicioActual.base_datos ? mapNombreBase(ejercicioActual.base_datos) : null;
    const resultado = await api("POST", "/api/ejecutar", { sesion: estado.sesionActiva, sql, db: dbObjetivo });
    estado.ultimoResultado = resultado;
    if (resultado.rescate_delimiter) {
      toast("Detecté una rutina sin DELIMITER. La ejecuté como una sola sentencia. " +
            "Lo correcto es: DELIMITER $$ ... END$$ ... DELIMITER ;", 6000);
    }

    const { estadoFinal, veredicto } = await evaluarYGuardar(resultado);
    renderBannerEstado(estadoFinal, veredicto, resultado);

    if (!resultado.ok_general) mostrarTab("mensajes");
    else if (veredicto === "difiere") mostrarTab("comparacion");
    else mostrarTab("resultado");

    await refrescarEstadoBd();
    renderSesionesHeader();
    renderRiel();
  } catch (e) {
    toast("Error de comunicación: " + e.message);
  } finally {
    document.getElementById("btn-ejecutar").disabled = false;
    document.getElementById("btn-cancelar").disabled = true;
  }
}

// Decide si el ejercicio queda "resuelto" en base a si el resultado REALMENTE
// coincide con la salida esperada del docx (cuando hay una para comparar),
// no simplemente si la sentencia corrió sin errores de SQL.
async function evaluarYGuardar(resultado) {
  let estadoFinal = "borrador";
  let veredicto = null;

  if (resultado.ok_general) {
    const ultima = ultimaSentenciaConGrilla(resultado);
    if (ejercicioActual.tabla_esperada && ultima) {
      try {
        const comp = await api("POST", "/api/comparar", {
          consigna: ejercicioActual.consigna,
          columnas: ultima.columnas,
          filas: ultima.filas,
          tabla_esperada: ejercicioActual.tabla_esperada,
        });
        estado.ultimaComparacion = comp;
        veredicto = comp.veredicto;
        if (veredicto === "coincide" || veredicto === "coincide_orden_distinto") {
          estadoFinal = "resuelto";
        } else if (veredicto === "difiere") {
          estadoFinal = "revisar";
        } else {
          estadoFinal = "resuelto"; // no_comparable: no hay nada contra qué comparar
        }
      } catch (e) {
        estadoFinal = "resuelto"; // si falla la comparación, no penalizamos al alumno
      }
    } else {
      estadoFinal = "resuelto"; // sin tabla esperada (DDL/DML/DCL/TCL/rutinas): alcanza con que corra bien
    }
  }

  await guardarSolucion(estadoFinal, { ok: resultado.ok_general, veredicto });
  return { estadoFinal, veredicto };
}

function renderBannerEstado(estadoFinal, veredicto, resultado) {
  const banner = document.getElementById("banner-estado");
  if (!banner) return;

  if (!resultado.ok_general) {
    banner.className = "banner-estado error";
    banner.innerHTML = "✗ Hubo un error al ejecutar. Mirá la solapa <b>Mensajes</b>.";
  } else if (estadoFinal === "resuelto" && (veredicto === "coincide" || veredicto === "coincide_orden_distinto")) {
    banner.className = "banner-estado ok";
    banner.innerHTML = veredicto === "coincide_orden_distinto"
      ? "✓ ¡Correcto! Coincide con la salida esperada (en otro orden) — <b>ejercicio resuelto</b>."
      : "✓ ¡Correcto! Coincide con la salida esperada — <b>ejercicio resuelto</b>.";
  } else if (veredicto === "difiere") {
    banner.className = "banner-estado revisar";
    banner.innerHTML = "✗ Corrió bien, pero el resultado <b>no coincide</b> con lo esperado. Mirá la solapa " +
      "<b>Comparación</b>. (todavía no se marca como resuelto)";
  } else if (estadoFinal === "resuelto") {
    banner.className = "banner-estado ok";
    banner.innerHTML = "✓ Ejecutado sin errores — <b>ejercicio resuelto</b> (este ejercicio no tiene una salida esperada para comparar).";
  } else {
    banner.className = "banner-estado";
    banner.innerHTML = "";
  }
}

function limpiarBannerEstado() {
  const banner = document.getElementById("banner-estado");
  if (banner) { banner.className = "banner-estado"; banner.innerHTML = ""; }
}

// Al entrar a un ejercicio ya evaluado antes, recordá el estado en vez de
// arrancar en blanco -- si quedó "a revisar" es útil que se note enseguida.
function restaurarBannerEstado() {
  const sol = solucionesCache[ejercicioActual.id];
  const banner = document.getElementById("banner-estado");
  if (!banner) return;
  if (sol && sol.estado === "resuelto") {
    banner.className = "banner-estado ok";
    banner.innerHTML = "✓ Ya resolviste este ejercicio correctamente.";
  } else if (sol && sol.estado === "revisar") {
    banner.className = "banner-estado revisar";
    banner.innerHTML = "✗ La última vez que lo corriste, el resultado no coincidía con lo esperado.";
  } else {
    limpiarBannerEstado();
  }
}

async function cancelar() {
  await api("POST", "/api/cancelar", { sesion: estado.sesionActiva });
}

function ultimaSentenciaConGrilla(resultado) {
  if (!resultado) return null;
  for (let i = resultado.sentencias.length - 1; i >= 0; i--) {
    if (resultado.sentencias[i].ok && resultado.sentencias[i].columnas.length) return resultado.sentencias[i];
  }
  return null;
}

function renderGrilla(cont, columnas, filas, truncado) {
  if (!columnas.length) {
    cont.innerHTML = "<div class='mensaje-ok'>Sin columnas (sentencia no-SELECT).</div>";
    return;
  }
  let html = `<table class="grilla"><thead><tr>${columnas.map((c) => `<th>${escapeHtml(c)}</th>`).join("")}</tr></thead><tbody>`;
  for (const f of filas) {
    html += "<tr>" + f.map((v) => v === null ? `<td class="null">NULL</td>` : `<td>${escapeHtml(v)}</td>`).join("") + "</tr>";
  }
  html += "</tbody></table>";
  if (truncado) html += `<div class="mensaje-ok">Mostrando ${filas.length} filas (hay más -- se cortó en 1000).</div>`;
  cont.innerHTML = html;
}

function renderResultado() {
  const cont = document.getElementById("panel-resultados");
  const r = estado.ultimoResultado;
  if (!r) { cont.innerHTML = "<div class='mensaje-ok'>Ejecutá con Ctrl+Enter.</div>"; return; }
  const ultima = ultimaSentenciaConGrilla(r);
  if (!ultima) {
    const noSelect = r.sentencias.filter((s) => s.ok);
    if (noSelect.length) {
      const s = noSelect[noSelect.length - 1];
      cont.innerHTML = `<div class="mensaje-ok">OK. Filas afectadas: ${s.filas_afectadas ?? 0} (${s.ms} ms)</div>`;
    } else {
      cont.innerHTML = "<div class='mensaje-ok'>Sin resultados.</div>";
    }
    return;
  }
  renderGrilla(cont, ultima.columnas, ultima.filas, ultima.truncado);
}

function renderEsperado() {
  const cont = document.getElementById("panel-resultados");
  const t = ejercicioActual.tabla_esperada;
  if (!t) { cont.innerHTML = "<div class='mensaje-ok'>Este ejercicio no tiene una tabla de salida esperada en el docx.</div>"; return; }
  cont.innerHTML = renderTablaDoc(t);
}

async function renderComparacion() {
  const cont = document.getElementById("panel-resultados");
  const r = estado.ultimoResultado;
  const ultima = ultimaSentenciaConGrilla(r);
  if (!ultima) { cont.innerHTML = "<div class='mensaje-ok'>Ejecutá una consulta primero.</div>"; return; }
  try {
    const comp = await api("POST", "/api/comparar", {
      consigna: ejercicioActual.consigna, columnas: ultima.columnas, filas: ultima.filas,
      tabla_esperada: ejercicioActual.tabla_esperada,
    });
    estado.ultimaComparacion = comp;
  } catch (e) {
    cont.innerHTML = `<div class="mensaje-error">${escapeHtml(e.message)}</div>`;
    return;
  }
  const c = estado.ultimaComparacion;
  const etiquetas = { coincide: "Coincide", coincide_orden_distinto: "Coincide (distinto orden)", difiere: "Difiere", no_comparable: "No comparable" };
  let html = `<div class="veredicto ${c.veredicto}">${etiquetas[c.veredicto] || c.veredicto}</div>`;
  if (c.veredicto !== "no_comparable") {
    html += `<div class="mensaje-ok">filas ${c.filas_obtenidas}/${c.filas_esperadas} · columnas ${c.columnas_obtenidas}/${c.columnas_esperadas} ·
      coincidentes ${c.coincidentes} · sólo esperado ${c.solo_en_esperado} · sólo obtenido ${c.solo_en_obtenido}</div>`;
  } else if (c.detalle) {
    html += `<div class="mensaje-ok">${escapeHtml(c.detalle)}</div>`;
  }

  if (c.veredicto === "difiere") {
    const encab = c.encabezados_esperados || [];
    if (c.filas_solo_en_esperado && c.filas_solo_en_esperado.length) {
      html += `<div style="margin-top:14px;font-size:12px;color:var(--texto-tenue)">
        Filas que esperaba el docx y NO aparecen en tu resultado:</div>`;
      html += renderTablaDiff(encab, c.filas_solo_en_esperado);
    }
    if (c.filas_solo_en_obtenido && c.filas_solo_en_obtenido.length) {
      html += `<div style="margin-top:14px;font-size:12px;color:var(--texto-tenue)">
        Filas que devolviste vos y NO estaban esperadas:</div>`;
      html += renderTablaDiff(encab, c.filas_solo_en_obtenido);
    }
    if (c.truncado_diff) {
      html += `<div class="mensaje-ok" style="margin-top:6px">(hay más diferencias de las que se muestran acá)</div>`;
    }
  }

  cont.innerHTML = html;
}

function renderTablaDiff(encabezados, filas) {
  let html = `<table class="grilla fila-diff-tabla"><thead><tr>${encabezados.map((c) => `<th>${escapeHtml(c)}</th>`).join("")}</tr></thead><tbody>`;
  for (const f of filas) {
    html += "<tr class='fila-diff'>" + f.map((v) => v === null || v === "" ? `<td class="null">∅</td>` : `<td>${escapeHtml(v)}</td>`).join("") + "</tr>";
  }
  html += "</tbody></table>";
  return html;
}

function renderMensajes() {
  const cont = document.getElementById("panel-resultados");
  const r = estado.ultimoResultado;
  if (!r) { cont.innerHTML = "<div class='mensaje-ok'>Sin mensajes.</div>"; return; }
  let html = "";
  for (const s of r.sentencias) {
    if (s.error) {
      html += `<div class="mensaje-error">✗ ${escapeHtml(s.sql.slice(0, 80))}\n${escapeHtml(s.error)}</div><hr style="border-color:var(--borde)">`;
    } else {
      html += `<div class="mensaje-ok">✓ ${escapeHtml(s.sql.slice(0, 80))} -- ${s.ms} ms`;
      if (s.warnings.length) html += `\n⚠ ${s.warnings.map(escapeHtml).join("\n⚠ ")}`;
      html += `</div>`;
    }
  }
  cont.innerHTML = html || "<div class='mensaje-ok'>Sin mensajes.</div>";
}

function mostrarTab(nombre) {
  estado.tab = nombre;
  document.querySelectorAll(".tab").forEach((t) => t.classList.toggle("activo", t.dataset.tab === nombre));
  if (nombre === "resultado") renderResultado();
  else if (nombre === "esperado") renderEsperado();
  else if (nombre === "comparacion") renderComparacion();
  else if (nombre === "mensajes") renderMensajes();
  else if (nombre === "ideal") renderIdeal();
}

function renderIdeal() {
  const cont = document.getElementById("panel-resultados");
  const ej = ejercicioActual;
  const miSol = solucionesCache[ej.id];

  let html = "";
  if (miSol && miSol.sql) {
    html += `<div style="margin-bottom:14px">
      <div style="font-size:12px;color:var(--texto-tenue);margin-bottom:4px">Tu solución</div>
      <pre class="sol-sql-bloque">${escapeHtml(miSol.sql || "")}</pre>
    </div>`;
  }

  if (ej.solucion_ideal && ej.solucion_ideal.sql) {
    html += `<div>
      <div style="font-size:12px;color:var(--texto-tenue);margin-bottom:4px">Solución ideal</div>
      <pre class="sol-sql-bloque ideal">${escapeHtml(ej.solucion_ideal.sql)}</pre>
      ${ej.solucion_ideal.notas ? `<div class="mensaje-ok" style="margin-top:6px">${escapeHtml(ej.solucion_ideal.notas)}</div>` : ""}
    </div>`;
  } else {
    html += `<div class="mensaje-ok">Todavía no hay una solución ideal cargada para este ejercicio.</div>`;
  }

  cont.innerHTML = html;
}

// ------------------------------------------------------------------ //
// Guardado / autosave
// ------------------------------------------------------------------ //
async function guardarSolucion(estadoSol, resultadoEjec) {
  const sql = getSql();
  const ultima_ejecucion = resultadoEjec ? { ok: resultadoEjec.ok, veredicto: resultadoEjec.veredicto } : null;
  const res = await api("PUT", `/api/soluciones/${ejercicioActual.id}`, { sql, estado: estadoSol, ultima_ejecucion });
  solucionesCache[ejercicioActual.id] = res;
  renderRiel();
  const chip = document.querySelector("#panel-consigna h2 .chip-estado");
  if (chip) chip.outerHTML = chipEstadoHtml(ejercicioActual.id);
}

// Guardar texto sin ejecutar nunca "inventa" un resuelto/revisar nuevo --
// esos estados sólo los decide evaluarYGuardar() después de correr la
// consulta de verdad. Pero si el texto es EXACTAMENTE el mismo que ya
// estaba guardado (por ejemplo, tocaste "Guardar" de nuevo sin cambiar
// nada tras resolverlo), no tiene sentido bajarlo a borrador: no hay
// ningún cambio sin verificar, así que se conserva el veredicto anterior.
function estadoParaGuardarSinEjecutar() {
  const sql = getSql();
  const previo = solucionesCache[ejercicioActual.id];
  if (previo && previo.sql === sql && (previo.estado === "resuelto" || previo.estado === "revisar")) {
    return previo.estado;
  }
  return "borrador";
}

async function guardarBorradorSiHaceFalta() {
  if (!ejercicioActual) return;
  const sql = getSql();
  const previo = solucionesCache[ejercicioActual.id];
  if ((previo ? previo.sql : "") !== sql && sql.trim()) {
    await guardarSolucion("borrador", null);
  }
}

let debounceTimer = null;
function autosaveDebounced() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(async () => {
    const estadoFinal = estadoParaGuardarSinEjecutar();
    await guardarSolucion(estadoFinal, null);
    restaurarBannerEstado();
  }, 800);
}

// ------------------------------------------------------------------ //
// Sesiones
// ------------------------------------------------------------------ //
async function renderSesionesHeader() {
  let sesiones;
  try {
    sesiones = await api("GET", "/api/sesiones");
  } catch (e) { return; }
  const cont = document.getElementById("sesiones-header");
  cont.innerHTML = "";
  for (const nombre of ["principal", "secundaria", "usuario"]) {
    const s = sesiones[nombre];
    const chip = document.createElement("div");
    chip.className = "sesion-chip" + (estado.sesionActiva === nombre ? " activa" : "");
    let color = "gris";
    if (s.conectada) color = s.en_transaccion ? "ambar" : "verde";
    chip.innerHTML = `<span class="dot ${color}"></span> ${nombre}`;
    chip.title = s.conectada ? `${s.usuario}@${s.db || "(sin bd)"} · conn ${s.connection_id}` : "clic para conectar";
    chip.onclick = async () => {
      if (!s.conectada) {
        const dbObjetivo = ejercicioActual ? mapNombreBase(ejercicioActual.base_datos) : null;
        let usuario = "root", password = "";
        if (nombre === "usuario") {
          usuario = prompt("Usuario MySQL a conectar (creado con CREATE USER):", "") || "";
          if (!usuario) return;
          password = prompt("Contraseña:", "") || "";
        }
        try {
          await api("POST", `/api/sesiones/${nombre}/conectar`, { usuario, password, db: dbObjetivo });
          toast(`Sesión ${nombre} conectada como ${usuario}`);
        } catch (e) {
          toast("No se pudo conectar: " + e.message, 5000);
        }
      }
      estado.sesionActiva = nombre;
      renderSesionesHeader();
    };
    if (s.en_transaccion) {
      chip.title += " · TRANSACCIÓN ABIERTA";
      const btnCommit = document.createElement("button");
      btnCommit.textContent = "✓"; btnCommit.title = "COMMIT";
      btnCommit.style.marginLeft = "4px";
      btnCommit.onclick = async (ev) => { ev.stopPropagation(); await api("POST", `/api/sesiones/${nombre}/tx`, { accion: "commit" }); renderSesionesHeader(); };
      const btnRollback = document.createElement("button");
      btnRollback.textContent = "↺"; btnRollback.title = "ROLLBACK";
      btnRollback.onclick = async (ev) => { ev.stopPropagation(); await api("POST", `/api/sesiones/${nombre}/tx`, { accion: "rollback" }); renderSesionesHeader(); };
      chip.appendChild(btnCommit);
      chip.appendChild(btnRollback);
    }
    cont.appendChild(chip);
  }
}

// ------------------------------------------------------------------ //
// Pill de MySQL
// ------------------------------------------------------------------ //
async function actualizarPillMysql() {
  try {
    const est = await api("GET", "/api/estado");
    const pill = document.getElementById("pill-mysql");
    if (est.mysql.proceso_vivo) {
      pill.innerHTML = `<span class="dot verde"></span> MySQL ${est.mysql.version} · puerto ${est.mysql.puerto}`;
    } else if (est.descarga.activo) {
      pill.innerHTML = `<span class="dot ambar"></span> ${escapeHtml(est.descarga.mensaje)} (${est.descarga.pct}%)`;
    } else {
      pill.innerHTML = `<span class="dot gris"></span> MySQL no disponible`;
    }
  } catch (e) {
    document.getElementById("pill-mysql").innerHTML = `<span class="dot gris"></span> sin conexión con el backend`;
  }
}

// ------------------------------------------------------------------ //
// Init
// ------------------------------------------------------------------ //
function bindEventos() {
  document.getElementById("btn-ejecutar").onclick = ejecutar;
  document.getElementById("btn-cancelar").onclick = cancelar;
  document.getElementById("btn-guardar").onclick = () => guardarSolucion(estadoParaGuardarSinEjecutar(), null).then(() => { restaurarBannerEstado(); toast("Guardado"); });
  document.getElementById("btn-anterior").onclick = anterior;
  document.getElementById("btn-siguiente").onclick = siguiente;
  document.querySelectorAll(".tab").forEach((t) => t.onclick = () => mostrarTab(t.dataset.tab));
  document.getElementById("chk-group-by").onchange = (ev) => {
    api("POST", `/api/sesiones/${estado.sesionActiva}/sqlmode`, { only_full_group_by: ev.target.checked });
  };

  document.addEventListener("keydown", (ev) => {
    if (ev.ctrlKey && ev.key === "Enter") { ev.preventDefault(); ejecutar(); }
    else if (ev.altKey && ev.key === "ArrowRight") { ev.preventDefault(); siguiente(); }
    else if (ev.altKey && ev.key === "ArrowLeft") { ev.preventDefault(); anterior(); }
    else if (ev.key === "Escape") { cancelar(); }
    else if (ev.ctrlKey && ev.key === "s") { ev.preventDefault(); guardarSolucion(estadoParaGuardarSinEjecutar(), null).then(() => { restaurarBannerEstado(); toast("Guardado"); }); }
  });

  if (!estado.usaCodeMirror) {
    document.getElementById("editor-fallback").addEventListener("input", autosaveDebounced);
    document.getElementById("editor-fallback").addEventListener("keydown", (ev) => {
      if (ev.key === "Tab") { ev.preventDefault(); document.execCommand("insertText", false, "  "); }
    });
  }
}

async function main() {
  initEditor();
  if (estado.usaCodeMirror) {
    estado.editor.on("change", autosaveDebounced);
  }
  bindEventos();
  await cargarRiel();
  await irA(1, 1);
  renderSesionesHeader();
  actualizarPillMysql();
  setInterval(actualizarPillMysql, 5000);
  setInterval(renderSesionesHeader, 8000);
}

main();
