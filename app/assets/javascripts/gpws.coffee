# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


lData = null
bData = null

_upcolor = 'rgba(100,150,100,1)'
_downcolor = 'rgba(150,100,100,1)'

ll = (_str, _nl=true) ->
    _log = $('#console')
    _log.text("#{_log.val()}\n #{_str}") if _nl
    _log.text("#{_log.val()}#{_str}") if not _nl
    _log.scrollTop(_log[0].scrollHeight)

main = () ->
    lData = $('#ldata').data('ldata')
    bData = $('#bdata').data('bdata')

    lDataPlot = getPlot()

    plotLayout = layoutPlot(lDataPlot.dataset.title)
    plotConfig = configurePlot()
    plot(lDataPlot, lData, bData, plotLayout, plotConfig)

    # ll(" ml5 version: #{ml5.version}", false)
    # ll('================================================================================')
    lstmSetup()

window.onload = main

plot = (_plt, _ld, _bd, _layout=null, _config=null) ->

    _ldr = _ld[..]
    _ldr.reverse()

    hrl = (_d) ->
        if _d < 0
            return _downcolor
        _upcolor

    _date = (row.date for row in _ld)
    _dater = (row.date for row in _ldr)
    _open = (row.open for row in _ld)
    _high = (row.high for row in _ld)
    _low = (row.low for row in _ld)
    _close = (row.close for row in _ld)
    _change = (row.change for row in _ld)
    _waterfall = ((row.close - _ldr[i-1].close) for row, i in _ldr when i isnt 0)
    _volume = (row.volume for row in _ld)
    _turnover = (row.tornover for row in _ld)
    _color = (hrl (row.change) for row in _ld)

    _scatterTrace = {
        # Scatter
        x: _date
        y: _close
        name: 'price'
        type: 'scatter'
        xaxis: 'x'
        yaxis: 'y'
        line: {color: 'black'}
        visible: true
    }

    _candleTrace = {
        x: _date
        open: _open
        high: _high
        low: _low
        close: _close
        name: 'price'
        type: 'candlestick'
        xaxis: 'x'
        yaxis: 'y'
        increasing: {line: {color: _upcolor}}
        decreasing: {line: {color: _downcolor}}
        line: {color: 'black'}
        base: _ld[0].close
        visible: false
    }

    _ohlcTrace = {
        x: _date
        open: _open
        high: _high
        low: _low
        close: _close
        name: 'price'
        type: 'ohlc'
        xaxis: 'x'
        yaxis: 'y'
        increasing: {line: {color: _upcolor}}
        decreasing: {line: {color: _downcolor}}
        line: {color: 'black'}
        base: _ld[0].close
        visible: false
    }

    _waterfallTrace = {
        x: _dater
        y: _waterfall
        base: _ldr[0].close
        name: 'price'
        type: 'waterfall'
        xaxis: 'x'
        yaxis: 'y'
        increasing: {marker: {color: _upcolor}}
        decreasing: {marker: {color: _downcolor}}
        visible: false
    }

    _brickTrace = plotBrick(_bd, _ldr[0].close)

    _tableTrace = {
        header: {
            values: [
                ['Date']
                ['Open']
                ['High']
                ['Low']
                ['Close']
                ['Change']
                ['Volume']
                ['Turover']
            ]
        }
        cells: {
            values: [
                _date
                _open
                _high
                _low
                _close
                _change
                _volume
                _turnover]}
        name: 'price'
        type: 'table'
        xaxis: 'x'
        yaxis: 'y'
        increasing: {line: {color: _upcolor}}
        decreasing: {line: {color: _downcolor}}
        line: {color: 'black'}
        base: _ld[0].close
        domain: {
            x: [0, 1]
            y: [0.02, 1]
        }
        visible: false
    }

    _volumeTrace = {
        x: _date
        y: _volume
        name: 'volume'
        type: 'bar'
        xaxis: 'x'
        yaxis: 'y2'
        marker: {
            color: _color
        }
        visible: true
    }

    _shapes = ({
            type: "circle"
            xref: 'x'
            x0: _tip.dateStart
            x1: _tip.dateEnd
            yref: 'y'
            y0: _tip.value + _bd.step
            y1: _tip.value - _bd.step
            line: {
                color: 'red'
                width: '5px'
            }
        } for _tip in _bd.tips)

    _localLayout = {
        grid: {
            rows: 2
            columns: 2
            subplots:[['xy', 'x2y'], ['xy2']]
        }
        xaxis: {
            domain: [0, 0.99]
            rangeslider: {visible: false}
            visible: true
        }
        xaxis2: {
            domain: [0.99, 1]
            rangeslider: {visible: false}
            visible: false
        }
        yaxis: {
            domain: [0.1, 1]
            visible: true
        }
        yaxis2: {
            domain: [0, 0.1]
            visible: true
        }
        shapes: _shapes
    }
    (_layout[_k] = _v) for _k, _v of _localLayout

    Plotly.newPlot(_plt, [
            _scatterTrace
            _candleTrace
            _ohlcTrace
            _waterfallTrace
            _brickTrace
            _tableTrace
            _volumeTrace
        ], _layout, _config)

plotBrick = (_bd, _base, _step = false) ->
    _trace = {
        x: []
        y: []
        text: []
        base: _base
        name: 'price'
        type: 'waterfall'
        xaxis: 'x2'
        yaxis: 'y'
        increasing: {marker: {color: _upcolor}}
        decreasing: {marker: {color: _downcolor}}
        visible: false
    }

    _trace.x.push(_x) for _x in _bd.bricks.x
    _trace.y.push(_y) for _y in _bd.bricks.y
    _trace.text.push("Close value: #{_value}") for _value in _bd.bricks.value

    # if not _step
    #     _step = 0
    #     _step += Math.abs(_row.change) for _row in _ld

    # console.log(_step)
    # console.log(_ld.length)
    # _step /= _ld.length
    # console.log(_step)

    # _index = 0
    # _last = _ld[0].close
    # for _row in _ld[1..]

    #     while(Math.abs(_row.close - _last) >= _step)
    #         _ = if (_row.close - _last) < 0 then -_step else _step
    #         _trace.x.push(_index++)
    #         _trace.y.push(_)

    #         _last += _

    _trace

layoutPlot = (_title='') ->
    {
        title: _title,
        showlegend: false,
        hovermode: 'closest',
        dragmode: 'pan',
        selectdirection: 'h',
        updatemenus: [{
            direction: 'right'
            y: 1
            yanchor: 'top'
            buttons: [{
                method: 'update'
                args: [
                    {'visible': [true, false, false, false,  false ,false, true]}
                    {'xaxis.domain': [0, 0.99]
                    'xaxis.visible': true
                    'xaxis2.domain': [0.99, 1]
                    'xaxis2.visible': false
                    'yaxis.domain': [0.12, 1]
                    'yaxis2.visible': true
                    'yaxis2.domain': [0, 0.1]
                    'yaxis2.visible': true}]
                label: 'Linear'
            }, {
                method: 'update'
                args: [
                    {'visible': [false, true, false, false,  false ,false, true]}
                    {'xaxis.domain': [0, 0.99]
                    'xaxis.visible': true
                    'xaxis2.domain': [0.99, 1]
                    'xaxis2.visible': false
                    'yaxis.domain': [0.12, 1]
                    'yaxis2.visible': true
                    'yaxis2.domain': [0, 0.1]
                    'yaxis2.visible': true}]
                label: 'Candles'
            }, {
                method: 'update'
                args: [
                    {'visible': [false, false, true, false,  false ,false, true]}
                    {'xaxis.domain': [0, 0.99]
                    'xaxis.visible': true
                    'xaxis2.domain': [0.99, 1]
                    'xaxis2.visible': false
                    'yaxis.domain': [0.12, 1]
                    'yaxis2.visible': true
                    'yaxis2.domain': [0, 0.1]
                    'yaxis2.visible': true}]
                label: 'Stick'
            }, {
                method: 'update'
                args: [
                    {'visible': [false, false, false, true,  false ,false, true]}
                    {'xaxis.domain': [0, 0.99]
                    'xaxis.visible': true
                    'xaxis2.domain': [0.99, 1]
                    'xaxis2.visible': false
                    'yaxis.domain': [0.12, 1]
                    'yaxis2.visible': true
                    'yaxis2.domain': [0, 0.1]
                    'yaxis2.visible': true}]
                label: 'Waterfall'
            }, {
                method: 'update'
                args: [
                    {'visible': [false, false, false, false,  true ,false, false]}
                    {'xaxis.domain': [0, 0.01]
                    'xaxis.visible': false
                    'xaxis2.domain': [0.01, 1]
                    'xaxis2.visible': true
                    'yaxis.domain': [0.02, 1]
                    'yaxis2.visible': true
                    'yaxis2.domain': [0, 0.01]
                    'yaxis2.visible': false}]
                label: 'Brick'
            }, {
                method: 'update'
                args: [
                    {'visible': [false, false, false, false, false ,true, false]}
                    {'xaxis.domain': [0, 0.99]
                    'xaxis.visible': false
                    'xaxis2.domain': [0.99, 1]
                    'xaxis2.visible': false
                    'yaxis.domain': [0.02, 1]
                    'yaxis.visible': false
                    'yaxis2.domain': [0, 0.01]
                    'yaxis2.visible': false}]
                label: 'Table'
            }]
        }]
    }

configurePlot = () ->
    {
        displayModeBar: true
        responsive: true
        scrollZoom: true
    }

getPlot = () ->
    _ = $('#stockPlot')[0]

    # _.addEventListener('click'
    #     (_e) ->
    #         console.log(_e)
    # )

    _

# LSTM NN

lstmnn = null

lstmSetup = () ->
    lstmnn = tf.sequential()
    lstmnn.add(tf.layers.dense({units: 1, inputShape: [1]}))

    lstmnn.compile({loss: 'meanSquaredError', optimizer: 'sgd'})

    # Generate some synthetic data for training.
    xs = tf.tensor2d([1, 2, 3, 4], [4, 1])
    ys = tf.tensor2d([1, 3, 5, 7], [4, 1])

    # Train the lstmnn using the data.
    lstmnn.fit(xs, ys, {epochs: 10}).then(() ->
        # Use the lstmnn to do inference on a data point the lstmnn hasn't seen before:
        lstmnn.predict(tf.tensor2d([5], [1, 1])).print()
        # Open the browser devtools to see the output
    )