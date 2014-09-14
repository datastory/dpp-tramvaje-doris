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


window.ig.displayLinka = (day, lnno, porno, time) ->
    container.classed \active yes
    heading.html "#day. 7. linka #lnno tramvaj #porno"
    prujezdyGraph.html ""
    (err, data) <~ d3.csv "../data/processed/spoje/#day-#lnno-#porno.csv", (line) ->
        for field in <[zastavka sloupek time zpozdeni]>
            line[field] = parseInt line[field], 10
        line.stop = window.ig.stops[line.zastavka]
        line
    data .= filter (.stop)
    scrollXIndex = null
    for datum, index in data
        if datum.time == time
            scrollXIndex = index
            break
    segmentWidth = 50
    height = 400
    y = d3.scale.linear!
        ..domain d3.extent data.map (.zpozdeni)
        ..range [height, 0]
    x = (d, i) ->
        if d is null then i = data.length
        i * segmentWidth + 50

    path = d3.svg.line!
        ..x x
        ..y (d) -> y d.zpozdeni
    prujezdyGraph
        ..attr \width x null
        ..attr \height height + 200

    yAxis = for s in [0 to y.domain!.1 by 60]
        s
    yAxis ++= for s in [0 to y.domain!.0 by -60]
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
    mainPath = prujezdyGraph.append \g
        ..attr \class \data
        ..append \path
            ..datum data
            ..attr \d path
    prujezdyGraph.append \g
        ..attr \class "axis axis-x"
        ..selectAll \g .data data .enter!append \g
            ..attr \transform -> "translate(#{(x ...) - segmentWidth / 2}, 0)"
            ..classed \selected (d, i) -> i is scrollXIndex
            ..append \text
                ..attr \transform (d, i) -> "translate(#{segmentWidth / 2 + 10}, #{height}) rotate(50)"
                ..text -> "#{it.stop.name}"
            ..append \text
                ..attr \transform (d, i) -> "translate(#{segmentWidth / 2 - 10}, #{height}) rotate(50)"
                ..attr \dx 13
                ..text -> "#{ig.humanTime it.time} | #{ig.humanZpozdeni it.zpozdeni}"
            ..append \path
                ..attr \class \datapoint
                ..attr \d symbol
                ..attr \transform (d, i) -> "translate(#{segmentWidth / 2}, #{y d.zpozdeni})"
            ..append \rect
                ..attr \x 0
                ..attr \y 0
                ..attr \height height
                ..attr \width segmentWidth

    prujezdyGraphContainer.0.0.scrollLeft = scrollXIndex * segmentWidth - (prujezdyGraphContainer.0.0.offsetWidth / 2)


