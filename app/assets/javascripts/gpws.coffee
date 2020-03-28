# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

main = () ->
    lData = $('#ldata').data('ldata')

    lDataPlot = getPlot()

    plotLayout = layoutPlot(lDataPlot.dataset.title)
    plotConfig = configurePlot()
    plot(lDataPlot, lData, plotLayout, plotConfig)

window.onload = main

plot = (_plt, _ld, _layout=null, _config=null) ->

    _ldr = _ld[..]
    _ldr.reverse()

    _upcolor = 'rgba(100,150,100,1)'
    _downcolor = 'rgba(150,100,100,1)'

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
        base: _ld[0].close
        name: 'price'
        type: 'waterfall'
        xaxis: 'x'
        yaxis: 'y'
        increasing: {marker: {color: _upcolor}}
        decreasing: {marker: {color: _downcolor}}
        visible: false
    }

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

    _layout.grid = {
        rows: 2
        columns: 1
        subplots:[['xy'], ['xy2']]
    }
    _layout.xaxis = {
        rangeslider: {
            visible: false
        }
    }
    _layout.yaxis = {domain: [0.12, 1]}
    _layout.yaxis2 = {domain: [0, 0.1]}

    Plotly.newPlot(_plt, [
            _scatterTrace
            _candleTrace
            _ohlcTrace
            _waterfallTrace
            _tableTrace
            _volumeTrace
        ], _layout, _config)

layoutPlot = (_title='') ->
    {
        title: _title,
        showlegend: false,
        hovermode: 'closest',
        dragmode: 'pan',
        selectdirection: 'h',
        updatemenus: [{
            y: 1
            yanchor: 'top'
            buttons: [{
                method: 'restyle'
                args: [
                    'visible'
                    [true, false, false, false, false, true]]
                label: 'Linear'
            }, {
                method: 'restyle'
                args: [
                    'visible'
                    [false, true, false, false, false, true]]
                label: 'Candles'
            }, {
                method: 'restyle'
                args: [
                    'visible'
                    [false, false, true, false, false, true]]
                label: 'Stick'
            }, {
                method: 'restyle'
                args: [
                    'visible'
                    [false, false, false, true, false, true]]
                label: 'Waterfall'
            }, {
                method: 'restyle'
                args: [
                    'visible'
                    [false, false, false, false, true, true]]
                label: 'Table'
            }]
        }]
    }

configurePlot = () ->
    {
        displayModeBar: true
        responsive: true
        scrollZoom: true
        showEditInChartStudio: true
        plotlyServerURL: "https://chart-studio.plotly.com"
    }

getPlot = () ->
    _ = $('#stockPlot')[0]

    _.addEventListener('click'
        (_e) ->
            console.log(_e)
    )

    _
