canvasWidth = 200
canvasHeight = 90
minuteBinning = 10_minutes
xValues = 24 * 60 / minuteBinning
lineColors = d3.scale.ordinal!
    ..range <[#e41a1c #377eb8 #4daf4a #984ea3 ]>

maxY = 240_seconds
map = null

canvasY = d3.scale.linear!
    ..domain [-60 maxY]
    ..range [canvasHeight, 0]
canvasX = d3.scale.linear!
    ..domain [0 xValues]
    ..range [0 canvasWidth]

drawZeroLine = (ctx) ->
    ctx.strokeStyle = '#666'
    ctx.beginPath!
    ctx.moveTo 0, Math.round canvasY 0
    ctx.lineTo canvasWidth, Math.round canvasY 0
    ctx.stroke!
    ctx.strokeStyle = '#ddd'
    ctx.beginPath!
    for y in [0 to maxY by 120]
        ctx.moveTo 0, Math.round canvasY y
        ctx.lineTo canvasWidth,Math.round canvasY y
    ctx.stroke!

drawTable = (stops) ->
    base = d3.select \body .append \ul
        ..attr \class \zastavky

    base.selectAll \li .data stops .enter!append \li
        ..append \span
            ..attr \class \name
            ..html (.name)
        ..on \click (stop) ->
            map.setView [stop.lat, stop.lon], 16
        ..each (stop) ->
            canvas = document.createElement \canvas
            @appendChild canvas
            canvas.width = canvasWidth
            canvas.height = canvasHeight
            ctx = canvas.getContext \2d
            drawZeroLine ctx
            for {medians}, index in stop.sloupky
                ctx.strokeStyle = lineColors index
                isDrawn = no
                for median, xPosition in medians
                    x = canvasX xPosition
                    y = canvasY median
                    if median is null
                        ctx.stroke! if isDrawn
                        isDrawn = no
                        continue
                    if not isDrawn
                        ctx.beginPath!
                        ctx.moveTo x, y
                        isDrawn = yes
                    else
                        ctx.lineTo x, y
                ctx.stroke! if isDrawn


drawMap = (stops) ->
    mapElement = document.createElement \div
    mapElement.setAttribute \id \map
    document.body.appendChild mapElement
    map := L.map do
        *   'map'
        *   fadeAnimation: false,
            minZoom: 6,
            maxZoom: 16
            maxBounds: [[50.354 14.128], [49.693 15.381]]
    map
        ..setView [50.07, 14.42], 12
        ..addLayer L.tileLayer do
            "http://hnmaps.blob.core.windows.net/tiles-desaturated/{z}/{x}/{y}.png"
            zIndex: 1 opacity: 0.7 attribution: '<a target="_blank" href="http://creativecommons.org/licenses/by-nc-sa/3.0/cz/" target = "_blank">CC BY-NC-SA 3.0 CZ</a> IHNED.cz, mapové data &copy; <a target="_blank" href="http://www.openstreetmap.org">OpenStreetMap.org</a>, <a target="_blank" href="http://www.infoprovsechny.cz/request/aktuln_verze_gtfs#incoming-988">dopravní data</a> <a target="_blank" href="http://dpp.cz">DPP Praha</a>'

    reasonableMax = stops[Math.round stops.length * 0.02].median_avg
    absoluteMax = stops[0].median_avg

    mapColors = d3.scale.linear!
        ..domain [0 to reasonableMax by reasonableMax / 6] ++ [absoluteMax]
        ..range <[#ffffb2 #fed976 #feb24c #fd8d3c #fc4e2a #e31a1c #b10026 #b10026]>

    addMarker = (stopOrSloupek, name) ->
        markerColor = mapColors stopOrSloupek.median_avg
        className = if stopOrSloupek.id % 2 then 'even' else 'odd'
        name += " " + if stopOrSloupek.id % 2 then '(do centra)' else '(z centra)'
        icon = L.divIcon do
            *   html: "<span style='border-color: #markerColor' title='#{name}'></span>"
                iconSize: [15 15]
                className: "station-marker #className"
        new L.marker [stopOrSloupek.lat, stopOrSloupek.lon], {icon}
            ..addTo map

    for stop in stops
        if stop.sloupky[0].lat
            for sloupek in stop.sloupky
                if sloupek and sloupek.lat
                    addMarker sloupek, stop.name

ig.drawZastavky = ->
    (err, stops) <~ d3.json "../data/processed/stops-median.json"
    drawMap stops
    drawTable stops

