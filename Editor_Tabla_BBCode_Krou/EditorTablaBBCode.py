#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Editor de Tabla BBCode — Compendio de Traducciones de Krou
===========================================================

Ventana gráfica para editar la tabla de traducciones y generar el BBCode de
la descripción del Compendio en Nexus Mods.

Uso:
    python EditorTablaBBCode.py        (o doble clic en el .exe portable)

Archivos que acompañan al programa (en la misma carpeta):
    tabla_mods.json   Los datos de la tabla (se guarda automáticamente).
    plantilla.txt     La descripción completa; los marcadores {TABLA} y
                      {LEYENDA} se reemplazan al generar el BBCode.

«Importar Excel…» (.xlsx / .xlsm):
    · Si el libro tiene varias hojas con datos, pide cuál usar.
    · Si la hoja tiene varias tablas (bloques de celdas separados por
      filas o columnas vacías), pide cuál (u «unir todas»).
    · Antes de importar se confirma qué columna corresponde a cada campo
      (ID | FOMOD | Formato | Nombre | Link trad | Link Mod) y si la
      primera fila son encabezados; los enlaces pueden ser texto o
      hipervínculos de Excel.

La lógica de generación (colores con contraste verificado para el tema claro
y oscuro de Nexus, tabla en una sola línea y textos de la descripción)
reproduce el generador original del Compendio.
"""

import datetime
import json
import os
import re
import sys
import traceback
import webbrowser

import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from tkinter.scrolledtext import ScrolledText

if sys.platform == "win32":
    try:
        from ctypes import windll
        windll.shcore.SetProcessDpiAwareness(1)   # texto nítido en pantallas HiDPI
    except Exception:
        pass

# ------------------------------------------------------------------ constantes
NOMBRE_APP = "Editor de Tabla BBCode — Compendio de Krou"
URL_DSD = "https://www.nexusmods.com/skyrimspecialedition/mods/107676"
LIMITE_NEXUS = 65_535          # tope teórico (bytes UTF-8) de una descripción
FORMATOS = ("ESP", "DSD", "Otro", "ESP/Otro")
COLORES_PREDETERMINADOS = {"ESP": "#B36BE0", "DSD": "#26A34A", "Otro": "#009BD0"}

# Texto por defecto de la plantilla; el contenido real se inyecta al
# empaquetar (ver scripts/editor_tabla/parchar_plantilla.py).
PLANTILLA_PREDETERMINADA = """[center][size=5][b]Las traducciones requieren el siguiente mod: [url=https://www.nexusmods.com/skyrimspecialedition/mods/107676]Dynamic String Distributor (DSD)[/url], sin esto no funcionarán.[/b][/size][/center]

[center][size=3][i]Trabajando para actualizar esto. En unos días habrá cambios :)[/i][/size][/center]

[hr]

[size=4][b][u]¿Qué es DSD?[/u][/b][/size]

[size=3]Es un complemento basado en SKSE que permite distribuir y modificar textos dinámicamente en el juego, mejorando la compatibilidad entre mods sin necesidad de editar directamente los archivos originales del juego o de otros mods.[/size]

[size=3]Compendio de traducciones usadas en mi conjunto de mods mediante [url=https://www.nexusmods.com/skyrimspecialedition/mods/107676]Dynamic String Distributor (DSD)[/url].[/size]

[center][size=4][b][u]Contiene las siguientes traducciones:[/u][/b][/size][/center]

[center]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/89307]Interesting NPCs (3DNPC) - Patch Collection[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/29194]Interesting NPCs SE (3DNPC)[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/162603]Adventurer's Lodge[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/160114]Agent Bonus Tweaks for Mara and Dibella[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/78623]AI Overhaul - Various Patches[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/21654]AI Overhaul SSE[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/70266]AI Overhaul - Open Cities Patches[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/48524]Argonian Upgrades[/url] [i](archivo principal y Imperious patch)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/164461]BeastHHBB - Skypatcher[/url] [i](archivo principal y parche 3DNPC Skypatcher)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/109302]C.O.I.N. - Smelting add-on for your COINS[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/52038]Conjure - More Summons[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/143887]Convert Gold To Perk Points[/url] [i](versión de 5K)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/129717]Elven Supremacy - Currency Swapper for Thalmor[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/123129]First Person Interactions[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/98923]First Person Para and Skydiving Patch[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/89208]Fishermen Sell Creation Club Fish[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/47670]Immersive Interactions - Animated Actions[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/23873]Imperious - All Mods Compatibility Patch - Not Just Interesting NPC's[/url] [i]la (Dinger32 Version)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/148647]Magic Fixes and Tweaks SKSE[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/97572]MMX452 Summon Chest[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/148359]Monster Squad[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/84004]Simply More Skill Trainers[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/130866]Orc Currency[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/33081]QAPP - Quests Award Perk Points[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/76017]Reb's Average Skooma SE[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/491]Exchange Currency SE[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/19456]Strange Runes[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/135488]True Light[/url] [i](para los complementos: True Light - Creation Club.esp, True Light - Shadows and Ambient.esp, True Light - USSEP Patch.esp y True Light Exteriors.esp)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/11467]Translocate - Mark And Recall Spells[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/133447]Unarmed - Damage Tweaks Knockdowns and Skill Progression[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/127897]Skyrim Silver - Currency Swapper for Windhelm[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/107437?tab=description]Gryphonknight Regalia - Breton Noble Armor (optional SMP)[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/165897?tab=description]Saint Jiub's Bookmarks[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/62530]Paragliding Vampire Werewolf Patch[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/136921]Perk Point Potion SkyPatched[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/161940]Archery Techniques (Additional Techniques NG)[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/54099]Pilgrim - A Religion Overhaul[/url]
[i]para parche ordinator (los 4 mods anteriores)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/172681]Muscle Matters - Functional growth and muscle atrophy[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/34552]Feral - Claw Unarmed Attacks for Beast Races - Vampires - Werewolves[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/42162]Skyrim Outfit System SE Revived[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/143978?tab=description]Bone Breaker Heavy Armour HIMBO SMP[/url]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/18994?tab=description]Weapons Armor Clothing and Clutter Fixes[/url] [i](y complementos de este mismo)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/37085?tab=description]Embers XD[/url] [i](y complementos de este mismo)[/i]
[url=https://www.nexusmods.com/skyrimspecialedition/mods/166094?tab=description]Missives - Voice and Quest Expansion[/url]
[/center]

[hr]

[center][size=4][b][u]Tabla completa de traducciones[/u][/b][/size][/center]

{LEYENDA}

{TABLA}

[hr]

[size=3][b]Acepto pedidos de traducciones en los comentarios, éstas requerirán el complemento de DSD y si me es posible la traducción del mod mediante esp o scripts (con los respectivos permisos del autor).[/b][/size]
"""


def ruta_base():
    """Carpeta del programa (igual como .py o como .exe compilado)."""
    if getattr(sys, "frozen", False):
        return os.path.dirname(os.path.abspath(sys.executable))
    return os.path.dirname(os.path.abspath(__file__))


RUTA_DATOS = os.path.join(ruta_base(), "tabla_mods.json")
RUTA_PLANTILLA = os.path.join(ruta_base(), "plantilla.txt")
RUTA_PREVIA = os.path.join(ruta_base(), "vista_previa.html")


# ------------------------------------------------------------------ datos JSON
def cargar_datos():
    """Carga tabla_mods.json (con valores predeterminados si falta o falla)."""
    predeterminado = {"colores": dict(COLORES_PREDETERMINADOS), "mods": []}
    try:
        with open(RUTA_DATOS, encoding="utf-8") as f:
            datos = json.load(f)
    except (OSError, ValueError):
        return predeterminado
    if not isinstance(datos, dict):
        return predeterminado
    colores = {}
    for clave, valor in predeterminado["colores"].items():
        colores[clave] = str(datos.get("colores", {}).get(clave, valor))
    mods = []
    for m in datos.get("mods", []):
        if not isinstance(m, dict):
            continue
        mods.append({
            "id": str(m.get("id") or "").strip(),
            "fomod": bool(m.get("fomod")),
            "formato": m.get("formato") if m.get("formato") in FORMATOS else "Otro",
            "nombre": str(m.get("nombre") or "").strip(),
            "link_trad": str(m.get("link_trad") or "").strip(),
            "link_mod": str(m.get("link_mod") or "").strip(),
        })
    return {"colores": colores, "mods": mods}


def guardar_datos(datos):
    """Guarda tabla_mods.json dejando una copia de seguridad .bak."""
    import shutil
    try:
        shutil.copy2(RUTA_DATOS, RUTA_DATOS + ".bak")
    except OSError:
        pass
    with open(RUTA_DATOS, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)


# ------------------------------------------------------------- normalización
def quitar_tildes(texto):
    """minúsculas sin tildes, para buscar y comparar encabezados."""
    import unicodedata
    s = str(texto or "").strip().lower()
    return "".join(c for c in unicodedata.normalize("NFKD", s)
                   if not unicodedata.combining(c))


def normalizar_fomod(valor):
    """'si' (o variantes) → True; vacío/'no' → False."""
    if valor is None:
        return False
    if isinstance(valor, bool):
        return valor
    return str(valor).strip().lower() in {"si", "sí", "s", "x", "1", "true",
                                          "yes", "✅"}


def normalizar_formato(valor):
    """Convierte el valor crudo del Excel a ESP / DSD / Otro / ESP/Otro."""
    s = quitar_tildes(valor).replace(" ", "")
    if "dsd" in s:
        return "DSD"
    esp = any(x in s for x in ("esp", "esl", "esm"))
    otro = any(x in s for x in ("otro", "txt", "ini"))
    if esp and otro:
        return "ESP/Otro"
    if esp:
        return "ESP"
    return "Otro"


def _a_texto_id(valor):
    if valor is None:
        return ""
    if isinstance(valor, float):
        return str(int(valor)) if valor.is_integer() else str(valor)
    if isinstance(valor, int):
        return str(valor)
    return str(valor).strip()


# ------------------------------------------------------------------ Excel
CAMPOS = ("id", "fomod", "formato", "nombre", "link_trad", "link_mod")
ETIQUETAS_CAMPO = {"id": "ID", "fomod": "FOMOD (instalador)",
                   "formato": "Formato", "nombre": "Nombre del mod",
                   "link_trad": "Link traducción",
                   "link_mod": "Link mod original"}
TOPE_FILAS_HOJA = 5000          # límites de escaneo de una hoja
TOPE_COLUMNAS_HOJA = 64
RE_URL = re.compile(r"^https?://", re.IGNORECASE)


def _letra_col(n):
    """1 → A, 2 → B … 27 → AA (para mostrar rangos tipo Excel)."""
    s = ""
    while n > 0:
        n, resto = divmod(n - 1, 26)
        s = chr(65 + resto) + s
    return s


def mapear_columna(titulo):
    """Nombre de encabezado → campo interno (None si no se reconoce)."""
    t = quitar_tildes(titulo)
    if not t:
        return None
    if "fomod" in t:
        return "fomod"
    if "formato" in t or t in ("tipo", "tipo de archivo"):
        return "formato"
    if "trad" in t:
        return "link_trad"
    if "mod" in t and ("link" in t or "url" in t or "original" in t
                       or "nexus" in t or "pagina" in t):
        return "link_mod"
    if "nombre" in t or "titulo" in t or t == "mod":
        return "nombre"
    if t in ("id", "#", "n°", "nº", "nro", "numero", "n."):
        return "id"
    return None


def abrir_workbook(ruta):
    """Abre un .xlsx/.xlsm con openpyxl (data_only: valores, no fórmulas)."""
    try:
        import openpyxl
    except ImportError:
        raise RuntimeError("Falta la librería openpyxl (pip install openpyxl)")
    try:
        return openpyxl.load_workbook(ruta, data_only=True)
    except Exception as e:
        raise RuntimeError("No se pudo abrir el Excel (debe ser .xlsx o "
                           f".xlsm):\n{e}")


def _celda_con_dato(valor):
    """¿La celda tiene algo útil? (None y "   " cuentan como vacías)."""
    return valor is not None and (not isinstance(valor, str) or valor.strip())


def _ocupacion(ws, tope_filas=TOPE_FILAS_HOJA, tope_cols=TOPE_COLUMNAS_HOJA):
    """Grilla de booleanos «la celda tiene datos» (recortada a los topes)."""
    nf = min(ws.max_row or 1, tope_filas)
    nc = min(ws.max_column or 1, tope_cols)
    ocup = []
    for fila in ws.iter_rows(min_row=1, max_row=nf, min_col=1, max_col=nc,
                             values_only=True):
        ocup.append([_celda_con_dato(v) for v in fila])
    return ocup


def detectar_tablas(ws):
    """Regiones rectangulares con datos de una hoja.

    Una «tabla» es un bloque de celdas separado del resto por filas o
    columnas vacías. Cada región trae r0/c0/r1/c1 (1-based, inclusivos),
    filas, cols, rango («A1:F189»), encabezados (letra + valor de la
    primera fila), reconocidos (cuántos encabezados mapean a campos) y
    puntaje (primero las que encabezados reconocen; a igualdad, la mayor).
    """
    ocup = _ocupacion(ws)
    if not ocup:
        return []
    nf, nc = len(ocup), len(ocup[0])
    visto = [[False] * nc for _ in range(nf)]
    regiones = []
    for i in range(nf):
        for j in range(nc):
            if not ocup[i][j] or visto[i][j]:
                continue
            pila = [(i, j)]
            visto[i][j] = True
            r0 = r1 = i
            c0 = c1 = j
            celdas = 0
            while pila:                                   # relleno 4-conexo
                y, x = pila.pop()
                celdas += 1
                r0, r1 = min(r0, y), max(r1, y)
                c0, c1 = min(c0, x), max(c1, x)
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if (0 <= yy < nf and 0 <= xx < nc
                            and ocup[yy][xx] and not visto[yy][xx]):
                        visto[yy][xx] = True
                        pila.append((yy, xx))
            regiones.append({"r0": r0 + 1, "c0": c0 + 1, "r1": r1 + 1,
                             "c1": c1 + 1, "celdas": celdas})

    # una tabla muy dispersa puede quedar cortada en piezas cuyos
    # rectángulos se solapan → se unen en una sola región
    cambio = True
    while cambio:
        cambio = False
        regiones.sort(key=lambda r: (-r["celdas"], r["r0"], r["c0"]))
        vivos = []
        usados = [False] * len(regiones)
        for a, ra in enumerate(regiones):
            if usados[a]:
                continue
            for b in range(a + 1, len(regiones)):
                if usados[b]:
                    continue
                rb = regiones[b]
                if not (rb["r1"] < ra["r0"] or rb["r0"] > ra["r1"]
                        or rb["c1"] < ra["c0"] or rb["c0"] > ra["c1"]):
                    ra["r0"] = min(ra["r0"], rb["r0"])
                    ra["r1"] = max(ra["r1"], rb["r1"])
                    ra["c0"] = min(ra["c0"], rb["c0"])
                    ra["c1"] = max(ra["c1"], rb["c1"])
                    ra["celdas"] += rb["celdas"]
                    usados[b] = True
                    cambio = True
            vivos.append(ra)
        regiones = vivos

    for reg in regiones:
        reg["filas"] = reg["r1"] - reg["r0"] + 1
        reg["cols"] = reg["c1"] - reg["c0"] + 1
        reg["rango"] = (f"{_letra_col(reg['c0'])}{reg['r0']}:"
                        f"{_letra_col(reg['c1'])}{reg['r1']}")
        reg["encabezados"] = [
            (_letra_col(c), ws.cell(row=reg["r0"], column=c).value)
            for c in range(reg["c0"], reg["c1"] + 1)]
        reg["reconocidos"] = sum(1 for _, v in reg["encabezados"]
                                 if mapear_columna(v))
        reg["puntaje"] = (reg["reconocidos"] * 10000
                          + reg["filas"] * reg["cols"])
    regiones.sort(key=lambda r: (-r["puntaje"], r["r0"]))
    return regiones


def hojas_con_datos(wb):
    """Hojas del libro que tienen al menos una celda con datos.

    Cada entrada: nombre, filas/cols con datos, ws (la hoja) y reconocidos
    (cuántos encabezados conocidos hay en su primera fila con datos).
    """
    hojas = []
    for ws in wb.worksheets:
        ocup = _ocupacion(ws)
        if not ocup or not ocup[0]:
            continue
        indices = [i for i, fila in enumerate(ocup) if any(fila)]
        if not indices:
            continue
        primera = indices[0]
        cols = sum(1 for j in range(len(ocup[0]))
                   if any(ocup[i][j] for i in indices))
        valores = next(ws.iter_rows(min_row=primera + 1,
                                    max_row=primera + 1,
                                    max_col=len(ocup[0]),
                                    values_only=True))
        reconocidos = sum(1 for v in valores
                          if _celda_con_dato(v) and mapear_columna(v))
        hojas.append({"nombre": ws.title, "filas": len(indices),
                      "cols": cols, "ws": ws, "reconocidos": reconocidos})
    return hojas


def _orden_hojas(hojas):
    """Índices ordenados: «Hoja1» primero; si no, la que más encabezados
    reconocidos tiene; a igualdad, el orden del libro."""
    def clave(i):
        h = hojas[i]
        if h["nombre"].strip().lower() == "hoja1":
            return (0, -h["reconocidos"], i)
        return (1, -h["reconocidos"], i)
    return sorted(range(len(hojas)), key=clave)


def mapear_columnas_region(ws, reg):
    """Mapa campo → columna leyendo los encabezados de la primera fila."""
    mapa = {}
    for c in range(reg["c0"], reg["c1"] + 1):
        campo = mapear_columna(ws.cell(row=reg["r0"], column=c).value)
        if campo and campo not in mapa:
            mapa[campo] = c
    return mapa


def _url_de_celda(celda):
    """URL de una celda de enlace: su valor o, si es solo texto amigable
    («aquí», «descargar»…), el hipervínculo de Excel que contenga."""
    v = celda.value
    s = "" if v is None else str(v).strip()
    if RE_URL.match(s):
        return s
    hl = getattr(celda, "hyperlink", None)
    if hl is not None and hl.target and RE_URL.match(str(hl.target).strip()):
        return str(hl.target).strip()
    return s


def leer_region(ws, reg, mapa=None, con_encabezados=True):
    """Importa los mods de una región detectada.

    mapa: campo → columna absoluta; si es None se detecta por encabezados
    y, cuando reconocen menos de 3, se usa el orden clásico ID..Link Mod.
    con_encabezados: si es True, la primera fila de la región no se importa.
    """
    if mapa is None:
        mapa = mapear_columnas_region(ws, reg)
        if len(mapa) < 3:
            mapa = {campo: reg["c0"] + i for i, campo in enumerate(CAMPOS)
                    if reg["c0"] + i <= reg["c1"]}
    fila_ini = reg["r0"] + 1 if con_encabezados else reg["r0"]
    mods = []
    informe = {"hoja": ws.title, "region": reg["rango"], "omitidas": 0,
               "avisos": [], "formatos_mapeados": {}}
    if fila_ini <= reg["r1"]:
        filas = ws.iter_rows(min_row=fila_ini, max_row=reg["r1"],
                             min_col=reg["c0"], max_col=reg["c1"])
        for desplaz, fila_celdas in enumerate(filas):
            r = fila_ini + desplaz
            celdas = {campo: fila_celdas[col - reg["c0"]]
                      for campo, col in mapa.items()}
            if all(not _celda_con_dato(c.value) for c in celdas.values()):
                continue                                   # fila vacía
            nombre = (str(celdas["nombre"].value or "").strip()
                      if "nombre" in celdas else "")
            if not nombre:
                informe["omitidas"] += 1
                continue
            crudo = (str(celdas["formato"].value or "").strip()
                     if "formato" in celdas else "")
            formato = normalizar_formato(crudo)
            if crudo and crudo not in FORMATOS:
                informe["formatos_mapeados"][crudo] = formato
            mod = {
                "id": (_a_texto_id(celdas["id"].value)
                        if "id" in celdas else ""),
                "fomod": (normalizar_fomod(celdas["fomod"].value)
                          if "fomod" in celdas else False),
                "formato": formato,
                "nombre": nombre,
                "link_trad": (_url_de_celda(celdas["link_trad"])
                              if "link_trad" in celdas else ""),
                "link_mod": (_url_de_celda(celdas["link_mod"])
                             if "link_mod" in celdas else ""),
            }
            mods.append(mod)
            for campo in ("link_trad", "link_mod"):
                enlace = mod[campo]
                if enlace and not RE_URL.match(enlace):
                    informe["avisos"].append(
                        f"Fila {r}: {campo.replace('_', ' ')} no parece un "
                        f"enlace: {enlace[:70]}")
    informe["total"] = len(mods)
    return mods, informe


def importar_excel(ruta, hoja=None, indice_tabla=None, con_encabezados=None):
    """Lee el Excel de traducciones (uso interno y primer arranque).

    Versión sin diálogos de importar_desde_excel: si hay varias hojas
    usa «Hoja1» (o la que mejor encabezados reconozca); si la hoja tiene
    varias tablas, la que mejor puntúe. Devuelve (mods, informe) igual
    que antes (el informe ahora también trae «region»).
    """
    wb = abrir_workbook(ruta)
    hojas = hojas_con_datos(wb)
    if not hojas:
        raise RuntimeError("El Excel no tiene datos en ninguna hoja.")
    if hoja is not None:
        candidatos = [h for h in hojas if h["nombre"] == hoja]
        if not candidatos:
            raise RuntimeError(
                f"No existe la hoja «{hoja}» (hojas con datos: "
                + ", ".join(h["nombre"] for h in hojas) + ")")
        destino = candidatos[0]
    else:
        destino = hojas[_orden_hojas(hojas)[0]]
    ws = destino["ws"]
    regiones = detectar_tablas(ws)
    if not regiones:
        raise RuntimeError(f"La hoja «{ws.title}» no tiene celdas con datos.")
    reg = regiones[indice_tabla] if indice_tabla is not None else regiones[0]
    if con_encabezados is None:
        # si la primera fila no encabeza nada conocido, tomamos todas las
        # filas como datos (el orden de columnas sigue siendo el clásico)
        con_encabezados = reg["reconocidos"] >= 2
    return leer_region(ws, reg, con_encabezados=con_encabezados)


# ------------------------------------------------------------------ BBCode
def celda_formato(fmt, colores, dual_espotro, dsd_link):
    """Celda «Formato» con su color (y enlace a DSD si corresponde)."""
    if fmt == "DSD":
        if dsd_link:
            return f"[url={URL_DSD}][color={colores['DSD']}]DSD[/color][/url]"
        return f"[color={colores['DSD']}]DSD[/color]"
    if fmt == "ESP":
        return f"[color={colores['ESP']}]ESP[/color]"
    if fmt == "Otro":
        return f"[color={colores['Otro']}]Otro[/color]"
    if fmt == "ESP/Otro":
        if dual_espotro:
            return (f"[color={colores['ESP']}]ESP[/color]/"
                    f"[color={colores['Otro']}]Otro[/color]")
        return f"[color={colores['ESP']}]ESP/Otro[/color]"
    raise ValueError(f"Formato desconocido: {fmt!r}")


def bloque_tabla(mods, colores, con_id, dual_espotro, dsd_link, txt_trad, txt_mod):
    """La tabla completa EN UNA SOLA LÍNEA (evita saltos dentro de [table])."""
    cols = (["ID"] if con_id else []) + ["FOMOD", "Formato", "Nombre",
                                         "Link trad", "Link Mod"]
    partes = ["[table]", "[tr]" + "".join(f"[th]{c}[/th]" for c in cols) + "[/tr]"]
    for m in mods:
        fomod = "✅" if m["fomod"] else "❌"
        celdas = []
        if con_id:
            celdas.append(str(m["id"]))
        celdas += [fomod,
                   celda_formato(m["formato"], colores, dual_espotro, dsd_link),
                   m["nombre"]]
        celdas.append(f"[url={m['link_trad']}]{txt_trad}[/url]" if m["link_trad"] else "—")
        celdas.append(f"[url={m['link_mod']}]{txt_mod}[/url]" if m["link_mod"] else "—")
        partes.append("[tr]" + "".join(f"[td]{c}[/td]" for c in celdas) + "[/tr]")
    partes.append("[/table]")
    return "".join(partes)


def leyenda(colores, dual_espotro):
    """Leyenda que explica los colores y símbolos de la tabla."""
    espotro = (f"[color={colores['ESP']}]ESP[/color][color={colores['Otro']}]/Otro[/color]"
               if dual_espotro else f"[color={colores['ESP']}]ESP/Otro[/color]")
    return (
        f"[size=2][b]Formato[/b]: [color={colores['ESP']}]ESP[/color] = reemplaza el .esp, .esl o .esm "
        f"· [url={URL_DSD}][color={colores['DSD']}]DSD[/color][/url] = traducción con "
        f"[url={URL_DSD}]Dynamic String Distributor[/url] "
        f"· [color={colores['Otro']}]Otro[/color] = reemplaza un .txt, .ini u otro archivo "
        f"· {espotro} = reemplaza el .esp y además otros archivos. "
        f"[b]FOMOD[/b]: ✅ = incluye instalador FOMOD · ❌ = sin FOMOD[/size]"
    )


def plantilla_predeterminada():
    """Plantilla de respaldo si no existe plantilla.txt."""
    if PLANTILLA_PREDETERMINADA.startswith("@@"):
        return ("[center][size=5][b]Las traducciones requieren el siguiente mod: "
                f"[url={URL_DSD}]Dynamic String Distributor (DSD)[/url], "
                "sin esto no funcionarán.[/b][/size][/center]\n"
                "\n[center][size=3][i]Trabajando para actualizar esto. "
                "En unos días habrá cambios :)[/i][/size][/center]\n"
                "\n[hr]\n"
                "\n{LEYENDA}\n"
                "\n{TABLA}\n")
    return PLANTILLA_PREDETERMINADA


def cargar_plantilla():
    """Lee plantilla.txt (o la predeterminada si no existe)."""
    try:
        with open(RUTA_PLANTILLA, encoding="utf-8") as f:
            contenido = f.read()
        if contenido.strip():
            return contenido
    except OSError:
        pass
    return plantilla_predeterminada()


def generar_bbcode(mods, colores, *, completo=True, con_id=True, dual_espotro=True,
                   dsd_link=True, txt_trad="Link Traducción",
                   txt_mod="Link Original", plantilla=None):
    """Genera el BBCode: la tabla sola o la descripción completa."""
    tabla = bloque_tabla(mods, colores, con_id, dual_espotro, dsd_link,
                         txt_trad, txt_mod)
    if not completo:
        return tabla
    plant = plantilla if plantilla is not None else cargar_plantilla()
    ley = leyenda(colores, dual_espotro)
    if "{TABLA}" in plant:
        return plant.replace("{LEYENDA}", ley).replace("{TABLA}", tabla)
    # plantilla sin marcadores: la tabla se agrega al final
    return plant.rstrip("\n") + "\n\n" + ley + "\n\n" + tabla + "\n"


def generar_con_presupuesto(mods, colores, *, compacta, completo, plantilla=None):
    """Genera según la versión elegida.

    Devuelve (bbcode, sin_enlace_dsd). Si la compacta sigue sobre el tope
    teórico de Nexus, se reintenta sin el hipervínculo DSD por fila (igual
    que el generador original del Compendio).
    """
    if compacta:
        base = dict(completo=completo, con_id=False, dual_espotro=False,
                    dsd_link=True, txt_trad="Traducción", txt_mod="Original",
                    plantilla=plantilla)
        bb = generar_bbcode(mods, colores, **base)
        if len(bb.encode("utf-8")) > LIMITE_NEXUS - 200:
            bb = generar_bbcode(mods, colores, **{**base, "dsd_link": False})
            return bb, True
        return bb, False
    bb = generar_bbcode(mods, colores, completo=completo, con_id=True,
                        dual_espotro=True, dsd_link=True,
                        txt_trad="Link Traducción", txt_mod="Link Original",
                        plantilla=plantilla)
    return bb, False


def verificar_bbcode(bb, mods, con_id, txt_trad, txt_mod):
    """Control de calidad del BBCode generado (devuelve lista de errores)."""
    errores = []
    n = len(mods)
    ncols = 6 if con_id else 5
    m = re.search(r"\[table\].*?\[/table\]", bb, flags=re.S)
    if not m:
        return ["no se encontró la tabla [table]…[/table]"]
    t = m.group(0)
    if t.count("[tr]") != n + 1 or t.count("[/tr]") != n + 1:
        errores.append(f"filas de tabla: {t.count('[tr]')} (esperadas {n + 1})")
    if t.count("[th]") != ncols or t.count("[/th]") != ncols:
        errores.append("cabecera de tabla incorrecta")
    if t.count("[td]") != n * ncols or t.count("[/td]") != n * ncols:
        errores.append(f"celdas: {t.count('[td]')} (esperadas {n * ncols})")
    n_si = sum(1 for x in mods if x["fomod"])
    if t.count("✅") != n_si or t.count("❌") != n - n_si:
        errores.append(f"FOMOD: ✅={t.count('✅')} ❌={t.count('❌')} "
                       f"(esperado {n_si}/{n - n_si})")
    con_trad = sum(1 for x in mods if x["link_trad"])
    con_mod = sum(1 for x in mods if x["link_mod"])
    if t.count(f"]{txt_trad}[/url]") != con_trad:
        errores.append(f"enlaces «{txt_trad}»: {t.count(f']{txt_trad}[/url]')} "
                       f"(esperados {con_trad})")
    if t.count(f"]{txt_mod}[/url]") != con_mod:
        errores.append(f"enlaces «{txt_mod}»: {t.count(f']{txt_mod}[/url]')} "
                       f"(esperados {con_mod})")
    for x in mods:
        if f"[td]{x['nombre']}[/td]" not in t:
            errores.append(f"nombre faltante: {x['nombre'][:60]}")
        if con_id and f"[td]{x['id']}[/td]" not in t:
            errores.append(f"ID faltante: {x['id']}")
    for a, b in (("[url", "[/url]"), ("[color=", "[/color]"), ("[size=", "[/size]"),
                 ("[b]", "[/b]"), ("[i]", "[/i]"), ("[center]", "[/center]"),
                 ("[table]", "[/table]"), ("[u]", "[/u]"), ("[tr]", "[/tr]"),
                 ("[td]", "[/td]"), ("[th]", "[/th]")):
        if bb.count(a) != bb.count(b):
            errores.append(f"tags desbalanceados: {a} ({bb.count(a)}) "
                           f"vs {b} ({bb.count(b)})")
    if "{TABLA}" in bb or "{LEYENDA}" in bb:
        errores.append("la plantilla tiene marcadores sin reemplazar")
    for sospechoso in ("TODO", "XXX", "NaN", "undefined"):
        if sospechoso in bb:
            errores.append(f"texto sospechoso: {sospechoso}")
    return errores


# ------------------------------------------------------- vista previa (HTML)
SIZE_CSS = {1: 11, 2: 12.5, 3: 14, 4: 17, 5: 20, 6: 24, 7: 30}


def bb2html(bb):
    """Convierte el BBCode a HTML (solo para la vista previa local)."""
    s = bb.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    for t, h in (("[b]", "<b>"), ("[/b]", "</b>"), ("[i]", "<i>"),
                 ("[/i]", "</i>"), ("[u]", "<u>"), ("[/u]", "</u>")):
        s = s.replace(t, h)
    s = re.sub(r"\[url=([^\]]+)\]", r'<a href="\1">', s)
    s = s.replace("[/url]", "</a>")
    s = re.sub(r"\[color=(#[0-9A-Fa-f]{6})\]", r'<span style="color:\1">', s)
    s = s.replace("[/color]", "</span>")
    s = re.sub(r"\[size=([1-7])\]", lambda mm: f'<span class="s{mm.group(1)}">', s)
    s = s.replace("[/size]", "</span>")
    m = re.search(r"\[table\].*?\[/table\]", s)
    tabla = None
    if m:
        t = m.group(0)
        tabla = (t.replace("[table]", '<div class="tblwrap"><table>')
                  .replace("[/table]", "</table></div>")
                  .replace("[tr]", "<tr>").replace("[/tr]", "</tr>")
                  .replace("[th]", "<th>").replace("[/th]", "</th>")
                  .replace("[td]", "<td>").replace("[/td]", "</td>"))
        s = s[: m.start()] + "\x00TBL\x00" + s[m.end():]
    s = re.sub(r"\[center\](.*?)\[/center\]", r'<div class="ctr">\1</div>',
               s, flags=re.S)
    s = s.replace("[hr]", "<hr>")
    s = s.replace("\x00TBL\x00", tabla or "")
    s = re.sub(r"\n", "<br>\n", s)
    if "[" in s.replace("<br>", ""):
        restos = sorted(set(re.findall(r"\[[a-z=/#0-9]{1,12}", s)))
        raise ValueError("tags BBCode sin convertir en la vista previa: "
                         + ", ".join(restos[:10]))
    return s


def vista_previa_html(bb):
    """Página HTML que simula el tema oscuro de Nexus (con botón de tema claro)."""
    css_size = "\n".join(f".s{k}{{font-size:{v}px}}" for k, v in SIZE_CSS.items())
    return f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>Vista previa — Descripción del Compendio (Krou)</title>
<style>
body {{ margin:0; background:#181818; color:#d8d8d8; font-family:'Segoe UI',Arial,Helvetica,sans-serif; font-size:14px; line-height:1.55; }}
body.claro {{ background:#f2f2f2; color:#222; }}
.banner {{ position:sticky; top:0; z-index:10; background:#242424; border-bottom:1px solid #444; padding:9px 16px; font-size:12.5px; color:#bbb; display:flex; gap:14px; align-items:center; justify-content:space-between; }}
body.claro .banner {{ background:#e6e6e6; border-color:#ccc; color:#555; }}
.banner button {{ background:#3a3a3a; color:#ddd; border:1px solid #555; border-radius:6px; padding:4px 12px; cursor:pointer; font-size:12px; }}
body.claro .banner button {{ background:#fff; color:#333; border-color:#aaa; }}
.wrap {{ max-width:980px; margin:0 auto; padding:26px 22px 90px; }}
a {{ color:#6fb3f2; }}
body.claro a {{ color:#1565c0; }}
hr {{ border:0; border-top:1px solid #4a4a4a; margin:20px 0; }}
body.claro hr {{ border-color:#c9c9c9; }}
.ctr {{ text-align:center; }}
.tblwrap {{ overflow-x:auto; margin:14px 0; }}
table {{ border-collapse:collapse; font-size:13px; }}
th, td {{ border:1px solid #4b4b4b; padding:4px 9px; text-align:left; vertical-align:top; }}
body.claro th, body.claro td {{ border-color:#b8b8b8; }}
th {{ background:#2a2a2a; }}
body.claro th {{ background:#e4e4e4; }}
{css_size}
.nota {{ color:#888; font-size:12px; }}
</style>
</head>
<body>
<div class="banner">
  <span><b>VISTA PREVIA</b> — simulación del tema oscuro de Nexus · este recuadro gris NO es parte de la descripción</span>
  <button onclick="document.body.classList.toggle('claro');this.textContent=document.body.classList.contains('claro')?'Tema oscuro':'Tema claro'">Tema claro</button>
</div>
<div class="wrap">
{bb2html(bb)}
<p class="nota">— Fin de la vista previa. El aspecto final puede variar ligeramente según el tema de Nexus. —</p>
</div>
</body>
</html>"""


# ================================================================== DIÁLOGOS
class DialogoEdicion:
    """Ventana modal para agregar o editar un mod."""

    def __init__(self, padre, mod=None, id_sugerido=""):
        self.resultado = None
        self.top = tk.Toplevel(padre)
        self.top.title("Editar mod" if mod else "Agregar mod")
        self.top.transient(padre)
        self.top.grab_set()
        self.top.resizable(False, False)

        base = mod or {"id": id_sugerido, "fomod": False, "formato": "ESP",
                       "nombre": "", "link_trad": "", "link_mod": ""}
        self.var_id = tk.StringVar(value=base.get("id", ""))
        self.var_fomod = tk.BooleanVar(value=bool(base.get("fomod")))
        self.var_formato = tk.StringVar(
            value=base.get("formato") if base.get("formato") in FORMATOS else "ESP")
        self.var_nombre = tk.StringVar(value=base.get("nombre", ""))
        self.var_trad = tk.StringVar(value=base.get("link_trad", "") or "")
        self.var_mod = tk.StringVar(value=base.get("link_mod", "") or "")

        marco = ttk.Frame(self.top, padding=16)
        marco.pack(fill="both", expand=True)

        def fila(r, texto, widget):
            ttk.Label(marco, text=texto).grid(row=r, column=0, sticky="e",
                                              padx=(0, 10), pady=4)
            widget.grid(row=r, column=1, sticky="we", pady=4)

        fila(0, "ID:", ttk.Entry(marco, textvariable=self.var_id, width=12))
        fila(1, "Formato:", ttk.Combobox(marco, textvariable=self.var_formato,
                                         values=FORMATOS, state="readonly",
                                         width=12))
        fila(2, "FOMOD:", ttk.Checkbutton(marco, text="Sí, incluye instalador FOMOD",
                                          variable=self.var_fomod))
        fila(3, "Nombre:", ttk.Entry(marco, textvariable=self.var_nombre, width=62))
        fila(4, "Link Traducción:", ttk.Entry(marco, textvariable=self.var_trad, width=62))
        fila(5, "Link Original:", ttk.Entry(marco, textvariable=self.var_mod, width=62))
        ttk.Label(marco, foreground="#777",
                  text=("Los links se muestran como «Link Traducción» y "
                        "«Link Original» dentro de la tabla.")).grid(
            row=6, column=1, sticky="w", pady=(2, 0))

        botones = ttk.Frame(marco)
        botones.grid(row=7, column=0, columnspan=2, sticky="e", pady=(14, 0))
        ttk.Button(botones, text="Cancelar", command=self.top.destroy).pack(
            side="right", padx=(8, 0))
        ttk.Button(botones, text="Aceptar", command=self.aceptar).pack(side="right")

        marco.columnconfigure(1, weight=1)
        self.top.bind("<Return>", lambda _e: self.aceptar())
        self.top.bind("<Escape>", lambda _e: self.top.destroy())
        marco.focus_set()
        self.top.wait_window()

    def aceptar(self):
        nombre = self.var_nombre.get().strip()
        if not nombre:
            messagebox.showwarning("Falta el nombre",
                                   "Escribe al menos el nombre del mod.",
                                   parent=self.top)
            return
        if "[" in nombre or "]" in nombre:
            if not messagebox.askyesno(
                    "Nombre con corchetes",
                    "El nombre contiene [ o ], que pueden romper el BBCode "
                    "en Nexus.\n¿Guardarlo igual?", parent=self.top):
                return
        self.resultado = {
            "id": self.var_id.get().strip(),
            "fomod": bool(self.var_fomod.get()),
            "formato": self.var_formato.get(),
            "nombre": nombre,
            "link_trad": self.var_trad.get().strip(),
            "link_mod": self.var_mod.get().strip(),
        }
        self.top.destroy()


class VentanaColores:
    """Edita los colores de ESP / DSD / Otro usados en la tabla."""

    def __init__(self, app):
        self.app = app
        self.top = tk.Toplevel(app)
        self.top.title("Colores del Formato")
        self.top.transient(app)
        self.top.grab_set()
        self.top.resizable(False, False)

        marco = ttk.Frame(self.top, padding=16)
        marco.pack(fill="both", expand=True)
        ttk.Label(marco, text="Colores usados en la columna Formato:").grid(
            row=0, column=0, columnspan=3, sticky="w", pady=(0, 10))

        self.vars = {}
        etiquetas = (("ESP", "ESP (morado):"), ("DSD", "DSD (verde):"),
                     ("Otro", "Otro (celeste):"))
        for i, (clave, texto) in enumerate(etiquetas):
            ttk.Label(marco, text=texto).grid(row=i + 1, column=0, sticky="e",
                                              padx=(0, 10), pady=4)
            var = tk.StringVar(
                value=app.datos["colores"].get(clave,
                                               COLORES_PREDETERMINADOS[clave]))
            ttk.Entry(marco, textvariable=var, width=10).grid(
                row=i + 1, column=1, sticky="w", pady=4)
            muestra = tk.Label(marco, text="Texto de muestra",
                               fg=self._pintar(var))
            muestra.grid(row=i + 1, column=2, padx=10, pady=4)
            var.trace_add("write",
                          lambda *_a, v=var, m=muestra: self._refrescar(v, m))
            self.vars[clave] = var

        ttk.Label(marco, foreground="#777",
                  text="Formato hexadecimal: #B36BE0, #26A34A, #009BD0, "
                       "#E07000… (también nombres: purple, green, skyblue)").grid(
            row=5, column=0, columnspan=3, sticky="w", pady=(10, 0))

        botones = ttk.Frame(marco)
        botones.grid(row=6, column=0, columnspan=3, sticky="e", pady=(16, 0))
        ttk.Button(botones, text="Cancelar", command=self.top.destroy).pack(
            side="right", padx=(8, 0))
        ttk.Button(botones, text="Aceptar", command=self.aceptar).pack(side="right")

    @staticmethod
    def _pintar(var):
        try:
            color = var.get().strip()
            import tkinter.colorchooser  # noqa: F401  (garantiza Tk activo)
            tk._default_root.winfo_rgb(color)
            return color
        except Exception:
            return "#555555"

    def _refrescar(self, var, muestra):
        muestra.config(fg=self._pintar(var))

    def aceptar(self):
        for clave, var in self.vars.items():
            color = var.get().strip()
            if not color:
                messagebox.showwarning("Color vacío",
                                       f"El color de {clave} no puede estar vacío.",
                                       parent=self.top)
                return
            try:
                self.top.winfo_rgb(color)
            except tk.TclError:
                messagebox.showwarning(
                    "Color no válido",
                    f"«{color}» no es un color válido.\n"
                    "Usa formato hexadecimal, por ejemplo #26A34A.",
                    parent=self.top)
                return
            self.app.datos["colores"][clave] = color
        self.app._guardar_automatico()
        self.top.destroy()


class VentanaPlantilla:
    """Editor de la plantilla de la descripción completa."""

    def __init__(self, app):
        self.app = app
        self.top = tk.Toplevel(app)
        self.top.title("Plantilla de la descripción")
        self.top.geometry("900x640")
        self.top.transient(app)
        self.top.grab_set()

        barra = ttk.Frame(self.top, padding=(10, 6))
        barra.pack(fill="x")
        ttk.Button(barra, text="💾 Guardar", command=self.guardar).pack(side="left")
        ttk.Button(barra, text="↩ Restaurar predeterminada",
                   command=self.restaurar).pack(side="left", padx=8)
        ttk.Label(barra, foreground="#777",
                  text="{TABLA} y {LEYENDA} se reemplazan al generar el BBCode"
                  ).pack(side="right")

        self.texto = ScrolledText(self.top, font=("Consolas", 10), undo=True,
                                  wrap="word")
        self.texto.pack(fill="both", expand=True, padx=10, pady=(4, 10))
        self.texto.insert("1.0", cargar_plantilla())

    def guardar(self):
        contenido = self.texto.get("1.0", "end").rstrip("\n") + "\n"
        faltan = [m for m in ("{TABLA}", "{LEYENDA}") if m not in contenido]
        if faltan:
            aviso = ("La plantilla no contiene " + " ni ".join(faltan) + ".\n"
                     "Sin esos marcadores la tabla se agregará al final.\n\n"
                     "¿Guardar así?")
            if not messagebox.askyesno("Faltan marcadores", aviso,
                                       parent=self.top):
                return
        with open(RUTA_PLANTILLA, "w", encoding="utf-8") as f:
            f.write(contenido)
        messagebox.showinfo("Plantilla", "Plantilla guardada.", parent=self.top)

    def restaurar(self):
        if messagebox.askyesno(
                "Restaurar",
                "¿Reemplazar el texto por la plantilla predeterminada?",
                parent=self.top):
            self.texto.delete("1.0", "end")
            self.texto.insert("1.0", plantilla_predeterminada())


class VentanaGenerar:
    """Muestra el BBCode generado, con opciones y botones de copiado."""

    def __init__(self, app):
        self.app = app
        self.top = tk.Toplevel(app)
        self.top.title("Generar BBCode")
        self.top.geometry("1000x720")
        self.top.transient(app)
        self.top.grab_set()

        opciones = ttk.LabelFrame(self.top, text=" Opciones ", padding=(12, 8))
        opciones.pack(fill="x", padx=10, pady=(10, 4))
        self.var_version = tk.StringVar(value="completa")
        ttk.Radiobutton(
            opciones, variable=self.var_version, value="completa",
            command=self.regenerar,
            text="Completa (con columna ID, colores duales y «Link Traducción»/"
                 "«Link Original»)").grid(row=0, column=0, sticky="w")
        ttk.Radiobutton(
            opciones, variable=self.var_version, value="compacta",
            command=self.regenerar,
            text="Compacta (respaldo si Nexus la rechaza por tamaño: sin ID, "
                 "textos de enlace cortos)").grid(row=1, column=0, sticky="w")
        self.var_solo_tabla = tk.BooleanVar(value=False)
        ttk.Checkbutton(opciones, variable=self.var_solo_tabla,
                        command=self.regenerar,
                        text="Solo la tabla (sin el resto de la descripción)"
                        ).grid(row=2, column=0, sticky="w", pady=(4, 0))

        marco_texto = ttk.Frame(self.top)
        marco_texto.pack(fill="both", expand=True, padx=10, pady=6)
        self.texto = ScrolledText(marco_texto, font=("Consolas", 10),
                                  wrap="none", undo=True)
        xsb = ttk.Scrollbar(marco_texto, orient="horizontal",
                            command=self.texto.xview)
        self.texto.configure(xscrollcommand=xsb.set)
        self.texto.pack(side="top", fill="both", expand=True)
        xsb.pack(side="bottom", fill="x")

        self.var_estado = tk.StringVar()
        ttk.Label(self.top, textvariable=self.var_estado,
                  padding=(12, 2)).pack(fill="x")

        botones = ttk.Frame(self.top, padding=(10, 8))
        botones.pack(fill="x")
        ttk.Button(botones, text="Regenerar", command=self.regenerar).pack(side="left")
        ttk.Button(botones, text="Vista previa (HTML)",
                   command=self.vista_previa).pack(side="left", padx=8)
        ttk.Button(botones, text="Guardar como…",
                   command=self.guardar_como).pack(side="left")
        ttk.Button(botones, text="Copiar al portapapeles",
                   command=self.copiar).pack(side="right")
        self.regenerar()

    def _generar(self):
        return generar_con_presupuesto(
            self.app.datos["mods"], self.app.datos["colores"],
            compacta=self.var_version.get() == "compacta",
            completo=not self.var_solo_tabla.get())

    def regenerar(self):
        bb, sin_dsd = self._generar()
        self.texto.delete("1.0", "end")
        self.texto.insert("1.0", bb)

        compacta = self.var_version.get() == "compacta"
        txt_trad, txt_mod = (("Traducción", "Original") if compacta
                             else ("Link Traducción", "Link Original"))
        errores = verificar_bbcode(bb, self.app.datos["mods"],
                                   con_id=not compacta,
                                   txt_trad=txt_trad, txt_mod=txt_mod)
        bytes_ = len(bb.encode("utf-8"))
        estado = (f"{len(self.app.datos['mods'])} mods · {len(bb):,} caracteres · "
                  f"{bytes_:,} bytes UTF-8")
        if bytes_ > LIMITE_NEXUS:
            estado += f" · SUPERA el tope de {LIMITE_NEXUS:,}"
        estado += " · Verificación: " + ("OK" if not errores
                                         else f"{len(errores)} ERROR(ES)")
        if sin_dsd:
            estado += " · sin enlace DSD por fila (para bajar del límite)"
        self.var_estado.set(estado.replace(",", "."))

        if errores:
            self.top.bell()
            messagebox.showwarning(
                "Verificación",
                "La verificación encontró problemas:\n\n• "
                + "\n• ".join(errores[:12]), parent=self.top)

    def copiar(self):
        texto = self.texto.get("1.0", "end").rstrip("\n")
        self.app.clipboard_clear()
        self.app.clipboard_append(texto)
        self.app.update()
        messagebox.showinfo(
            "Copiado",
            "BBCode copiado al portapapeles.\n\nPégalo en la descripción de "
            "tu mod en Nexus Mods.", parent=self.top)

    def guardar_como(self):
        ruta = filedialog.asksaveasfilename(
            parent=self.top, title="Guardar BBCode",
            initialfile="descripcion_compendio_bbcode.txt",
            defaultextension=".txt", confirmoverwrite=True,
            filetypes=[("Archivo de texto", "*.txt")])
        if ruta:
            with open(ruta, "w", encoding="utf-8") as f:
                f.write(self.texto.get("1.0", "end").rstrip("\n") + "\n")
            messagebox.showinfo("Guardado", f"Guardado en:\n{ruta}",
                                parent=self.top)

    def vista_previa(self):
        bb = self.texto.get("1.0", "end").rstrip("\n")
        try:
            html = vista_previa_html(bb)
        except Exception as e:
            messagebox.showerror("Vista previa",
                                 f"No se pudo generar la vista previa:\n{e}",
                                 parent=self.top)
            return
        with open(RUTA_PREVIA, "w", encoding="utf-8") as f:
            f.write(html)
        webbrowser.open("file://" + os.path.abspath(RUTA_PREVIA))


# ------------------------------------------------ diálogos de importación
class DialogoElegirHoja:
    """Pide qué hoja del Excel usar cuando hay varias con datos."""

    def __init__(self, padre, hojas, indice_inicial=0, modal=True):
        self.hojas = hojas
        self.indice = None
        self.top = tk.Toplevel(padre)
        self.top.title("Elegir hoja del Excel")
        self.top.transient(padre)
        self.top.resizable(False, False)

        marco = ttk.Frame(self.top, padding=16)
        marco.pack(fill="both", expand=True)
        ttk.Label(marco, text="El Excel tiene varias hojas con datos.\n"
                              "¿Cuál quieres usar para la tabla?").grid(
            row=0, column=0, sticky="w", pady=(0, 10))

        self.lista = tk.Listbox(marco, width=66,
                                height=min(8, len(hojas)),
                                activestyle="dotbox")
        for h in hojas:
            texto = (f"{h['nombre']} — {h['filas']} filas × "
                     f"{h['cols']} columnas con datos")
            if h["reconocidos"]:
                texto += f" · {h['reconocidos']} encabezados reconocidos"
            self.lista.insert("end", texto)
        self.lista.grid(row=1, column=0, sticky="we")
        self.lista.selection_set(indice_inicial)
        self.lista.see(indice_inicial)
        self.lista.bind("<Double-Button-1>", lambda _e: self.aceptar())

        botones = ttk.Frame(marco)
        botones.grid(row=2, column=0, sticky="e", pady=(14, 0))
        ttk.Button(botones, text="Cancelar",
                   command=self.top.destroy).pack(side="right", padx=(8, 0))
        ttk.Button(botones, text="Aceptar",
                   command=self.aceptar).pack(side="right")
        self.top.bind("<Return>", lambda _e: self.aceptar())
        self.top.bind("<Escape>", lambda _e: self.top.destroy())
        if modal:
            self.top.grab_set()
            self.top.wait_window()

    def aceptar(self):
        sel = self.lista.curselection()
        if not sel:
            messagebox.showwarning("Elegir hoja", "Selecciona una hoja.",
                                   parent=self.top)
            return
        self.indice = sel[0]
        self.top.destroy()


class DialogoElegirTabla:
    """Pide qué tabla (bloque de celdas) usar cuando la hoja tiene varias."""

    def __init__(self, padre, ws, regiones, indice_inicial=0, modal=True):
        self.ws = ws
        self.regiones = list(regiones)
        self.region = None
        self.top = tk.Toplevel(padre)
        self.top.title("Elegir tabla de la hoja")
        self.top.transient(padre)
        self.top.resizable(False, False)

        # opción extra si hay varias: una región que las une todas
        self.union = None
        if len(regiones) > 1:
            u = {
                "r0": min(r["r0"] for r in regiones),
                "c0": min(r["c0"] for r in regiones),
                "r1": max(r["r1"] for r in regiones),
                "c1": max(r["c1"] for r in regiones),
            }
            u["filas"] = u["r1"] - u["r0"] + 1
            u["cols"] = u["c1"] - u["c0"] + 1
            u["rango"] = (f"{_letra_col(u['c0'])}{u['r0']}:"
                            f"{_letra_col(u['c1'])}{u['r1']}")
            u["encabezados"] = [
                (_letra_col(c), ws.cell(row=u["r0"], column=c).value)
                for c in range(u["c0"], u["c1"] + 1)]
            u["reconocidos"] = sum(1 for _, v in u["encabezados"]
                                    if mapear_columna(v))
            self.union = u

        marco = ttk.Frame(self.top, padding=16)
        marco.pack(fill="both", expand=True)
        ttk.Label(marco, text=(
            f"En la hoja «{ws.title}» se detectaron {len(regiones)} tablas "
            "(bloques de celdas separados por filas o columnas vacías).\n"
            "¿Cuál quieres usar? («Unir todas» las toma como una sola).")
            ).grid(row=0, column=0, sticky="w", pady=(0, 10))

        self.lista = tk.Listbox(marco, width=70,
                                height=min(9, len(regiones) + 1),
                                activestyle="dotbox")
        for i, reg in enumerate(regiones):
            texto = (f"Tabla {i + 1} — {reg['rango']} · {reg['filas']} "
                     f"filas × {reg['cols']} columnas")
            titulos = [str(v) for _, v in reg["encabezados"]
                       if mapear_columna(v)]
            if titulos:
                texto += " · encabezados: " + ", ".join(titulos[:4])
            self.lista.insert("end", texto)
        if self.union is not None:
            u = self.union
            self.lista.insert(
                "end", f"Unir todas las tablas — {u['rango']} · "
                       f"{u['filas']} filas × {u['cols']} columnas")
        self.lista.grid(row=1, column=0, sticky="we")
        self.lista.selection_set(indice_inicial)
        self.lista.see(indice_inicial)
        self.lista.bind("<Double-Button-1>", lambda _e: self.aceptar())

        botones = ttk.Frame(marco)
        botones.grid(row=2, column=0, sticky="e", pady=(14, 0))
        ttk.Button(botones, text="Cancelar",
                   command=self.top.destroy).pack(side="right", padx=(8, 0))
        ttk.Button(botones, text="Aceptar",
                   command=self.aceptar).pack(side="right")
        self.top.bind("<Return>", lambda _e: self.aceptar())
        self.top.bind("<Escape>", lambda _e: self.top.destroy())
        if modal:
            self.top.grab_set()
            self.top.wait_window()

    def aceptar(self):
        sel = self.lista.curselection()
        if not sel:
            messagebox.showwarning("Elegir tabla", "Selecciona una tabla.",
                                   parent=self.top)
            return
        i = sel[0]
        self.region = (self.regiones[i] if i < len(self.regiones)
                       else self.union)
        self.top.destroy()


class DialogoImportarExcel:
    """Confirma la importación: columnas, encabezados y destino."""

    def __init__(self, padre, ws, region, mods_actuales=0, modal=True):
        self.ws = ws
        self.region = region
        self.mods_actuales = mods_actuales
        self.resultado = None          # (mods, informe, reemplazar)
        self.top = tk.Toplevel(padre)
        self.top.title("Importar desde Excel")
        self.top.transient(padre)
        self.top.resizable(False, False)

        # sugerencia de mapeo: por encabezados; si reconocen poco, por orden
        sugerido = mapear_columnas_region(ws, region)
        if len(sugerido) >= 3:
            sugerido_enc = True
        else:
            sugerido_enc = False
            sugerido = {campo: region["c0"] + i
                        for i, campo in enumerate(CAMPOS)
                        if region["c0"] + i <= region["c1"]}

        marco = ttk.Frame(self.top, padding=16)
        marco.pack(fill="both", expand=True)
        ttk.Label(marco, text=(
            f"Hoja «{ws.title}» · tabla {region['rango']} · "
            f"{region['filas']} filas × {region['cols']} columnas.")
            ).grid(row=0, column=0, sticky="w", pady=(0, 10))

        # ---- mapeo de columnas
        self._por_etiqueta = {}
        etiquetas = []
        for despl, (letra, valor) in enumerate(region["encabezados"]):
            titulo = "" if valor is None else str(valor).strip()
            et = f"{letra} · {titulo[:26]}" if titulo else letra
            self._por_etiqueta[et] = region["c0"] + despl
            etiquetas.append(et)
        self._NINGUNA = "— ninguna —"

        col_frame = ttk.LabelFrame(marco, text=" Columnas de la tabla ",
                                   padding=(12, 8))
        col_frame.grid(row=1, column=0, sticky="w", pady=(0, 10))
        self.combos = {}
        for i, campo in enumerate(CAMPOS):
            ttk.Label(col_frame, text=ETIQUETAS_CAMPO[campo] + ":").grid(
                row=i, column=0, sticky="e", padx=(0, 10), pady=3)
            var = tk.StringVar()
            combo = ttk.Combobox(col_frame, textvariable=var, width=26,
                                 state="readonly",
                                 values=[self._NINGUNA] + etiquetas)
            col = sugerido.get(campo)
            var.set(self._etiqueta_de_columna(col) if col is not None
                    else self._NINGUNA)
            combo.grid(row=i, column=1, sticky="w", pady=3)
            combo.bind("<<ComboboxSelected>>",
                       lambda _e: self._vista_previa())
            self.combos[campo] = var
        self.var_enc = tk.BooleanVar(value=sugerido_enc)
        ttk.Checkbutton(
            col_frame, variable=self.var_enc,
            text="La primera fila de la tabla son los encabezados "
                 "(no se importa)",
            command=self._vista_previa).grid(
            row=len(CAMPOS), column=0, columnspan=2, sticky="w", pady=(8, 0))

        # ---- destino
        dest = ttk.LabelFrame(marco, text=" Al importar ", padding=(12, 8))
        dest.grid(row=2, column=0, sticky="w", pady=(0, 10))
        self.var_reemplazar = tk.BooleanVar(value=True)
        ttk.Radiobutton(dest, variable=self.var_reemplazar, value=True,
                        text=f"Reemplazar la tabla actual "
                             f"({mods_actuales} mods)").pack(anchor="w")
        self.etq_anadir = ttk.Radiobutton(
            dest, variable=self.var_reemplazar, value=False,
            text=f"Añadir al final de la tabla actual")
        self.etq_anadir.pack(anchor="w")

        # ---- vista previa
        prev = ttk.LabelFrame(marco, text=" Vista previa (primeras filas) ",
                              padding=(12, 8))
        prev.grid(row=3, column=0, sticky="w", pady=(0, 6))
        self.previo = tk.Text(prev, width=76, height=7, wrap="none",
                              font=("Consolas", 9), state="disabled",
                              background="#f6f6f6", relief="flat")
        self.previo.pack(fill="both", expand=True)

        botones = ttk.Frame(marco)
        botones.grid(row=4, column=0, sticky="e", pady=(8, 0))
        ttk.Button(botones, text="Cancelar",
                   command=self.top.destroy).pack(side="right", padx=(8, 0))
        ttk.Button(botones, text="Importar",
                   command=self.aceptar).pack(side="right")
        self.top.bind("<Return>", lambda _e: self.aceptar())
        self.top.bind("<Escape>", lambda _e: self.top.destroy())
        self._vista_previa()
        if modal:
            self.top.grab_set()
            self.top.wait_window()

    def _etiqueta_de_columna(self, col):
        for et, c in self._por_etiqueta.items():
            if c == col:
                return et
        return self._NINGUNA

    def _mapa_elegido(self):
        mapa = {}
        for campo, var in self.combos.items():
            et = var.get()
            if et in self._por_etiqueta:
                mapa[campo] = self._por_etiqueta[et]
        return mapa

    def _vista_previa(self):
        try:
            mods, _info = leer_region(self.ws, self.region,
                                      mapa=self._mapa_elegido(),
                                      con_encabezados=self.var_enc.get())
        except Exception:
            mods = []
        self.etq_anadir.configure(
            text=f"Añadir al final de la tabla actual "
                 f"(quedarían {self.mods_actuales + len(mods)} mods)")
        self.previo.configure(state="normal")
        self.previo.delete("1.0", "end")
        if not mods:
            self.previo.insert(
                "end", "(no hay filas para importar con esta combinación;\n"
                       "prueba marcando o desmarcando la casilla de "
                       "encabezados)")
        else:
            for m in mods[:5]:
                self.previo.insert(
                    "end",
                    f"{m['id'] or '·'}  {'✅' if m['fomod'] else '❌'}  "
                    f"{m['formato']:<8} {m['nombre'][:46]:<46} "
                    f"{_corto(m['link_trad'])}\n")
            if len(mods) > 5:
                self.previo.insert("end",
                                   f"… y {len(mods) - 5} filas más\n")
        self.previo.configure(state="disabled")

    def aceptar(self):
        mapa = self._mapa_elegido()
        if "nombre" not in mapa:
            messagebox.showwarning(
                "Importar", "Falta asignar la columna del nombre del mod.",
                parent=self.top)
            return
        if len(set(mapa.values())) != len(mapa):
            messagebox.showwarning(
                "Importar", "Hay una columna de Excel asignada a dos campos; "
                            "revísalo.", parent=self.top)
            return
        try:
            mods, info = leer_region(self.ws, self.region, mapa=mapa,
                                     con_encabezados=self.var_enc.get())
        except Exception as e:
            messagebox.showerror("Importar",
                                 f"No se pudo leer la tabla:\n{e}",
                                 parent=self.top)
            return
        if not mods:
            messagebox.showwarning(
                "Importar", "No se encontraron filas con nombre de mod.\n"
                            "Prueba marcando o desmarcando la casilla de "
                            "encabezados, o cambia las columnas.",
                parent=self.top)
            return
        self.resultado = (mods, info, bool(self.var_reemplazar.get()))
        self.top.destroy()


# ===================================================================== APP
def _corto(url):
    """Versión corta de un enlace para mostrarlo en la tabla."""
    if not url:
        return "—"
    m = re.search(r"/mods/(.+)$", url)
    if m:
        return "…/mods/" + m.group(1)[:14]
    return url.replace("https://", "").replace("http://", "")[:24]


class Aplicacion(tk.Tk):
    """Ventana principal: la tabla de mods con su barra de herramientas."""

    def __init__(self):
        super().__init__()
        self.title(NOMBRE_APP)
        self.geometry("1180x680")
        self.minsize(960, 540)
        self.hora_guardado = ""
        self.datos = cargar_datos()

        if not self.datos["mods"]:
            # primer arranque: importar un Excel que esté en la misma carpeta
            ruta = os.path.join(ruta_base(), "Lista de traducciones.xlsx")
            if os.path.exists(ruta):
                try:
                    mods, _info = importar_excel(ruta)
                    if mods:
                        self.datos["mods"] = mods
                        guardar_datos(self.datos)
                except Exception:
                    pass

        self._construir_ui()
        self._poblar()

    # ----------------------------------------------------------------- ui
    def _construir_ui(self):
        barra = ttk.Frame(self, padding=(10, 8))
        barra.pack(fill="x")
        ttk.Button(barra, text="➕ Agregar", command=self.agregar).pack(side="left")
        ttk.Button(barra, text="✏️ Editar", command=self.editar).pack(
            side="left", padx=(6, 0))
        ttk.Button(barra, text="🗑 Eliminar", command=self.eliminar).pack(
            side="left", padx=(6, 0))
        ttk.Button(barra, text="⬆", width=4,
                   command=lambda: self.mover(-1)).pack(side="left", padx=(14, 0))
        ttk.Button(barra, text="⬇", width=4,
                   command=lambda: self.mover(1)).pack(side="left", padx=(6, 0))
        ttk.Button(barra, text="📥 Importar Excel…",
                   command=self.importar_desde_excel).pack(side="left",
                                                           padx=(14, 0))
        ttk.Button(barra, text="🎨 Colores…",
                   command=lambda: VentanaColores(self)).pack(side="left",
                                                               padx=(6, 0))
        ttk.Button(barra, text="📝 Plantilla…",
                   command=lambda: VentanaPlantilla(self)).pack(side="left",
                                                                 padx=(6, 0))
        ttk.Button(barra, text="💾 Guardar",
                   command=self._guardar_automatico).pack(side="left",
                                                          padx=(6, 0))
        ttk.Button(barra, text="📋 Generar BBCode",
                   command=lambda: VentanaGenerar(self)).pack(side="right")

        busq = ttk.Frame(self, padding=(10, 0))
        busq.pack(fill="x")
        ttk.Label(busq, text="Buscar:").pack(side="left")
        self.var_busqueda = tk.StringVar()
        ttk.Entry(busq, textvariable=self.var_busqueda).pack(
            side="left", fill="x", expand=True, padx=8)
        self.var_busqueda.trace_add("write", lambda *_: self._poblar())

        marco = ttk.Frame(self)
        marco.pack(fill="both", expand=True, padx=10, pady=6)
        columnas = ("id", "fomod", "formato", "nombre", "trad", "mod")
        self.tabla = ttk.Treeview(marco, columns=columnas, show="headings",
                                  selectmode="extended")
        titulos = {"id": "ID", "fomod": "FOMOD", "formato": "Formato",
                   "nombre": "Nombre", "trad": "Link trad", "mod": "Link Mod"}
        anchos = {"id": 60, "fomod": 64, "formato": 82, "nombre": 470,
                  "trad": 135, "mod": 135}
        for c in columnas:
            self.tabla.heading(c, text=titulos[c])
            self.tabla.column(c, width=anchos[c],
                              anchor="center" if c in ("id", "fomod", "formato")
                              else "w", stretch=(c == "nombre"))
        ysb = ttk.Scrollbar(marco, orient="vertical", command=self.tabla.yview)
        self.tabla.configure(yscrollcommand=ysb.set)
        self.tabla.pack(side="left", fill="both", expand=True)
        ysb.pack(side="right", fill="y")
        self.tabla.tag_configure("par", background="#f2f4f8")

        self.tabla.bind("<Double-1>", lambda _e: self.editar())
        self.tabla.bind("<Return>", lambda _e: self.editar())
        self.tabla.bind("<Delete>", lambda _e: self.eliminar())
        self.tabla.bind("<Alt-Up>", lambda _e: self.mover(-1))
        self.tabla.bind("<Alt-Down>", lambda _e: self.mover(1))
        self.tabla.bind("<Button-3>", self._menu_contextual)

        self.var_estado = tk.StringVar()
        ttk.Label(self, textvariable=self.var_estado,
                  padding=(12, 5)).pack(fill="x")

    def _poblar(self):
        self.tabla.delete(*self.tabla.get_children())
        filtro = quitar_tildes(self.var_busqueda.get())
        visibles = 0
        for i, m in enumerate(self.datos["mods"]):
            if filtro:
                campos = quitar_tildes(f'{m["id"]} {m["nombre"]} {m["formato"]}')
                if filtro not in campos:
                    continue
            self.tabla.insert(
                "", "end", iid=str(i), tags=("par",) if i % 2 else (),
                values=(m["id"], "✅" if m["fomod"] else "❌", m["formato"],
                        m["nombre"], _corto(m["link_trad"]),
                        _corto(m["link_mod"])))
            visibles += 1
        self._actualizar_estado(visibles)

    def _actualizar_estado(self, visibles=None):
        total = len(self.datos["mods"])
        vis = total if visibles is None else visibles
        texto = f"{total} mods" + (f" · {vis} visibles" if vis != total else "")
        if self.hora_guardado:
            texto += f" · guardado {self.hora_guardado}"
        self.var_estado.set(texto)

    def _guardar_automatico(self):
        guardar_datos(self.datos)
        self.hora_guardado = datetime.datetime.now().strftime("%H:%M")
        self._actualizar_estado()

    # ------------------------------------------------------------ acciones
    def agregar(self):
        numeros = [int(m["id"]) for m in self.datos["mods"]
                   if str(m.get("id", "")).isdigit()]
        siguiente = str(max(numeros) + 1) if numeros else ""
        dlg = DialogoEdicion(self, id_sugerido=siguiente)
        if dlg.resultado:
            self.datos["mods"].append(dlg.resultado)
            self.var_busqueda.set("")
            self._poblar()
            self._guardar_automatico()
            iid = str(len(self.datos["mods"]) - 1)
            self.tabla.selection_set(iid)
            self.tabla.see(iid)

    def editar(self):
        sel = self.tabla.selection()
        if not sel:
            self.var_estado.set("Selecciona un mod (doble clic o Enter para editar).")
            self.bell()
            return
        i = int(sel[0])
        dlg = DialogoEdicion(self, mod=self.datos["mods"][i])
        if dlg.resultado:
            self.datos["mods"][i] = dlg.resultado
            self._poblar()
            self._guardar_automatico()
            self.tabla.selection_set(str(i))
            self.tabla.see(str(i))

    def eliminar(self):
        sel = self.tabla.selection()
        if not sel:
            return
        if len(sel) == 1:
            nombre = self.datos["mods"][int(sel[0])]["nombre"]
            texto = f"¿Eliminar «{nombre[:70]}» de la tabla?"
        else:
            texto = f"¿Eliminar {len(sel)} mods de la tabla?"
        if messagebox.askyesno("Eliminar", texto, parent=self):
            for iid in sorted((int(x) for x in sel), reverse=True):
                del self.datos["mods"][iid]
            self._poblar()
            self._guardar_automatico()

    def mover(self, delta):
        sel = self.tabla.selection()
        if not sel:
            return
        i = int(sel[0])
        j = i + delta
        mods = self.datos["mods"]
        if not (0 <= j < len(mods)):
            return
        mods[i], mods[j] = mods[j], mods[i]
        self._poblar()
        self._guardar_automatico()
        self.tabla.selection_set(str(j))
        self.tabla.see(str(j))

    def _menu_contextual(self, evento):
        iid = self.tabla.identify_row(evento.y)
        if iid:
            self.tabla.selection_set(iid)
        menu = tk.Menu(self, tearoff=0)
        menu.add_command(label="Editar", command=self.editar)
        menu.add_command(label="Eliminar", command=self.eliminar)
        menu.add_separator()
        menu.add_command(label="Agregar nuevo", command=self.agregar)
        menu.tk_popup(evento.x_root, evento.y_root)

    def importar_desde_excel(self):
        """Flujo completo: elegir archivo → hoja → tabla → columnas."""
        ruta = filedialog.askopenfilename(
            parent=self, title="Importar Excel de traducciones",
            filetypes=[("Excel", "*.xlsx *.xlsm"),
                       ("Todos los archivos", "*.*")])
        if not ruta:
            return
        try:
            wb = abrir_workbook(ruta)
            hojas = hojas_con_datos(wb)
            if not hojas:
                raise RuntimeError("El archivo no tiene datos en ninguna "
                                   "hoja.")
        except Exception as e:
            messagebox.showerror("Importar",
                                 f"No se pudo leer el Excel:\n{e}", parent=self)
            return

        # 1) hoja
        if len(hojas) == 1:
            hoja = hojas[0]
        else:
            dlg = DialogoElegirHoja(self, hojas,
                                    indice_inicial=_orden_hojas(hojas)[0])
            if dlg.indice is None:
                return
            hoja = hojas[dlg.indice]

        # 2) tabla dentro de la hoja
        ws = hoja["ws"]
        regiones = detectar_tablas(ws)
        if not regiones:
            messagebox.showwarning(
                "Importar", f"La hoja «{ws.title}» no tiene celdas con datos.",
                parent=self)
            return
        if len(regiones) == 1:
            region = regiones[0]
        else:
            dlg = DialogoElegirTabla(self, ws, regiones)
            if dlg.region is None:
                return
            region = dlg.region

        # 3) confirmar columnas / encabezados / destino
        dlg = DialogoImportarExcel(self, ws, region,
                                   mods_actuales=len(self.datos["mods"]))
        if not dlg.resultado:
            return
        mods, info, reemplazar = dlg.resultado
        if reemplazar:
            self.datos["mods"] = mods
        else:
            self.datos["mods"] += mods
        self.var_busqueda.set("")
        self._poblar()
        self._guardar_automatico()

        from collections import Counter
        conteo = Counter(m["formato"] for m in mods)
        origen = (f"de la hoja «{info['hoja']}» (tabla {info['region']})")
        if reemplazar:
            partes = [f"Se importaron {info['total']} mods {origen}, "
                      "reemplazando la tabla anterior."]
        else:
            partes = [f"Se añadieron {info['total']} mods {origen} "
                      f"(la tabla ahora tiene {len(self.datos['mods'])})."]
        partes.append("Formato: " + " · ".join(
            f"{k}: {v}" for k, v in sorted(conteo.items())))
        partes.append(f"Con FOMOD: {sum(1 for m in mods if m['fomod'])}")
        if info["omitidas"]:
            partes.append(f"Filas sin nombre omitidas: {info['omitidas']}")
        if info["formatos_mapeados"]:
            partes.append("Valores de Formato convertidos: "
                          + ", ".join(f"«{k}» → {v}" for k, v
                                      in sorted(info["formatos_mapeados"].items())))
        if info["avisos"]:
            partes.append("Avisos:\n" + "\n".join(info["avisos"][:8]))
        messagebox.showinfo("Importar", "\n\n".join(partes), parent=self)


# ------------------------------------------------------------------ arranque
def _excepcion_global(tipo, valor, tb):
    """Guarda cualquier error inesperado en error.log y lo muestra."""
    try:
        with open(os.path.join(ruta_base(), "error.log"), "a",
                  encoding="utf-8") as f:
            f.write("".join(traceback.format_exception(tipo, valor, tb)) + "\n")
    except Exception:
        pass
    try:
        if tk._default_root is not None:
            messagebox.showerror(
                "Error inesperado",
                "Ocurrió un error; el detalle quedó en error.log "
                "(en la misma carpeta del programa).",
                parent=tk._default_root)
    except Exception:
        pass


def main():
    sys.excepthook = _excepcion_global
    app = Aplicacion()
    app.report_callback_exception = (
        lambda t, v, tb: _excepcion_global(t, v, tb))
    app.mainloop()


if __name__ == "__main__":
    main()
