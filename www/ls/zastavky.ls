canvasWidth = 200
canvasHeight = 90
minuteBinning = 10_minutes
xValues = 24 * 60 / minuteBinning
lineColors = d3.scale.ordinal!
    ..range <[#e41a1c #377eb8 #4daf4a #984ea3 ]>

maxY = 1200_seconds

canvasY = d3.scale.sqrt!
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




ig.drawZastavky = ->
    (err, stops) <~ d3.json "../data/processed/stops-median.json"
    drawTable stops

