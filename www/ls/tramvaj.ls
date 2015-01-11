container = d3.select 'body' .append \div
    ..attr \class \tramvaj
container.append \div
    ..attr \class \closebtn
    ..html "X"
    ..on \click -> container.classed \active no
heading = container.append \h1
prujezdyGraphContainer = container.append \div
    ..attr \class \prujezdyGraph
prujezdyGraph = prujezdyGraphContainer.append \svg

stopsToDisplayInMultilineMode = 20
window.ig.displayLinky = (linky) ->
    container.classed \active yes
    {day, time} = linky.0
    heading.html "#day. 7. linka #{linky.map (.lnno) .join ', '} tramvaj #{linky.map (.porno) .join ', '}"
    prujezdyGraph.html ""
    (err, data) <~ async.map linky, ({day, lnno, porno}, cb) ->
        (err, data) <~ d3.csv do
            "../data/processed/spoje/#day-#lnno-#porno.csv"
            (line) ->
                for field in <[zastavka sloupek time zpozdeni]>
                    line[field] = parseInt line[field], 10
                line.stop = window.ig.stops[line.zastavka]
                line
        data .= filter -> it.stop && (it.zpozdeni || it.zpozdeni == 0)
        data.sort (a, b) -> a.time - b.time
        cb null, data

    firstData = data.0
    mainScrollXIndex = null
    dataToUse = for dataset, index in data
        dataset .= filter (item, itemIndex) ->
            return true if dataset[itemIndex + 1] is void
            return true if item.time == linky[index].time
            item.stop.id != dataset[itemIndex + 1].stop.id

        scrollXIndex = getScrollXIndex dataset, linky[index].time
        if index == 0
            mainScrollXIndex = scrollXIndex
        scrollXIndexOffset = mainScrollXIndex - scrollXIndex
        if linky.length == 1
            dataset
        else
            startIndex = scrollXIndex - stopsToDisplayInMultilineMode
            start = Math.max do
                startIndex
                0
            dataset.slice start, scrollXIndex + 1
    minLength = Math.min ...dataToUse.map (.length)
    for dataset, index in dataToUse
        if dataset.length > minLength
            dataToUse[index] .= slice dataset.length - minLength

    if linky.length > 1
        mainScrollXIndex = stopsToDisplayInMultilineMode
        firstData = dataToUse.0
    for dataset in dataToUse
        for stop, index in dataset
            # console.log index, firstData[index]
            stop.plannedDifference = stop.time - firstData[index].time
            stop.actualDifference = stop.plannedDifference + stop.zpozdeni
    segmentWidth = 50
    height = 400
    allPoints = [].concat ...dataToUse
    y = d3.scale.linear!
        ..domain d3.extent allPoints.map (.actualDifference)
        ..range [height, 0]
    x = (d, i) ->
        if d is null then i = firstData.length
        i * segmentWidth + 50

    actualLine = d3.svg.line!
        ..x x
        ..y (d) -> y d.actualDifference

    plannedLine = d3.svg.line!
        ..x x
        ..y (d) -> y d.plannedDifference

    prujezdyGraph
        ..attr \width 30 + x null
        ..attr \height height + 400

    yAxis = for s in [60 to y.domain!.1 by 60]
        s
    yAxis ++= for s in [-60 to y.domain!.0 by -60]
        s

    prujezdyGraph.append \g
        ..attr \class "axis axis-y"
        ..selectAll \line .data yAxis .enter!append \line
            ..classed \zero -> it == 0
            ..attr \x1 40
            ..attr \x2 x null
            ..attr \y1 y
            ..attr \y2 y
        ..selectAll \text .data yAxis .enter!append \text
            ..attr \x 30
            ..attr \y y
            ..attr \dy 3
            ..attr \text-anchor \end
            ..text -> "#{it}s"


    symbol = d3.svg.symbol!
        ..type \circle
        ..size 20
    actualPath = prujezdyGraph.append \g
        ..attr \class "data actual"
        ..selectAll \g.linka .data dataToUse .enter!append \g
            ..attr \class \linka
            ..append \path
                ..attr \class \dataline
                ..attr \d actualLine
            ..selectAll \path.datapoint .data(-> it) .enter!append \path
                ..attr \class \datapoint
                ..attr \d symbol
                ..attr \transform (d, i) -> "translate(#{i * segmentWidth + 50}, #{y d.actualDifference})"

    plannedPath = prujezdyGraph.append \g
        ..attr \class "data planned"
        ..selectAll \path .data dataToUse .enter!append \path
            ..attr \class \dataline
            ..attr \d plannedLine

    prujezdyGraph.append \g
        ..attr \class "axis axis-x"
        ..selectAll \g .data firstData .enter!append \g
            ..attr \transform -> "translate(#{(x ...) - segmentWidth / 2}, 0)"
            ..classed \selected (d, i) -> i is mainScrollXIndex
            ..append \text
                ..attr \transform (d, i) -> "translate(#{segmentWidth / 2 + 10}, #{height}) rotate(50)"
                ..text (d, i) ->
                    names = dataToUse.map -> it[i].stop.name
                    prevName = null
                    names .= filter ->
                        if it == prevName
                            no
                        else
                            prevName := it
                            yes
                    "#{names.join ' | '}"
            ..append \text
                ..attr \transform (d, i) -> "translate(#{segmentWidth / 2 - 10}, #{height}) rotate(50)"
                ..attr \dx 13
                ..text (d, i) ->
                    if dataToUse.length == 1
                        "#{ig.humanTime d.time} | #{ig.humanZpozdeni d.zpozdeni}"
                    else
                        zpozdenis = dataToUse.map -> ig.humanZpozdeni it[i].zpozdeni
                        zpozdenis.join " | "


            ..append \rect
                ..attr \x 0
                ..attr \y 0
                ..attr \height height
                ..attr \width segmentWidth

    prujezdyGraphContainer.0.0.scrollLeft = mainScrollXIndex * segmentWidth - (prujezdyGraphContainer.0.0.offsetWidth / 2)


getScrollXIndex = (data, time) ->
    scrollXIndex = null
    for datum, index in data
        if datum.time == time
            scrollXIndex = index
            break
    scrollXIndex
