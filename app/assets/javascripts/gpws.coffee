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

    _upcolor = 'rgba(100,150,100,1)'
    _downcolor = 'rgba(150,100,100,1)'

    hrl = (_d) ->
        if _d < 0
            return _downcolor
        _upcolor

    _date = (row.date for row in _ld)
    _open = (row.open for row in _ld)
    _high = (row.high for row in _ld)
    _low = (row.low for row in _ld)
    _close = (row.close for row in _ld)
    _change = (row.change for row in _ld)
    _volume = (row.volume for row in _ld)
    _turnover = (row.tornover for row in _ld)
    _color = (hrl (row.change) for row in _ld)
    _measure = ('relative' for row in _ld)

    _d = {
        # Scatter
        x: _date,
        y: _close,
        # Candels and OHLC
        open: _open,
        high: _high,
        low: _low,
        close: _close,
        # Table
        header: {
            values: [
                ['Date'],
                ['Open'],
                ['High'],
                ['Low'],
                ['Close'],
                ['Change'],
                ['Volume'],
                ['Turover']
            ]
        },
        cells: {
            values: [_date, _open, _high, _low, _close, _change, _volume, _turnover]
        },
        # Common
        name: 'price',
        type: 'scatter',
        xaxis: 'x',
        yaxis: 'y',
        increasing: {line: {color: _upcolor}},
        decreasing: {line: {color: _downcolor}},
        line: {color: 'black'}
    }

    _v = {
        x: _date,
        y: _volume,
        name: 'volume',
        type: 'bar',
        xaxis: 'x',
        yaxis: 'y2',
        marker: {
            color: _color
        }
    }

    _layout.grid = {
        rows: 2,
        columns: 1,
        subplots:[['xy'], ['xy2']]
    }
    _layout.xaxis = {
        rangeslider: {
            visible: false
        }
    }
    _layout.yaxis = {domain: [0.12, 1]}
    _layout.yaxis2 = {domain: [0, 0.1]}

    Plotly.newPlot(_plt, [_d, _v], _layout, _config)

layoutPlot = (_title='') ->
    {
        title: _title,
        showlegend: false,
        hovermode: 'closest',
        dragmode: 'pan',
        selectdirection: 'h',
        updatemenus: [{
            y: 1,
            yanchor: 'top',
            buttons: [{
                method: 'restyle',
                args: ['type', ['scatter', 'bar']],
                label: 'Linear'
            }, {
                method: 'restyle',
                args: ['type', ['candlestick', 'bar']],
                label: 'Candles'
            }, {
                method: 'restyle',
                args: ['type', ['ohlc', 'bar']],
                label: 'Stick'
            }, {
                method: 'restyle',
                args: ['type', ['waterfall', 'bar']],
                label: 'Waterfall'
            }, {
                method: 'restyle',
                args: ['type', ['table', 'bar']],
                label: 'Table'
            }]
        }]
    }

configurePlot = () ->
    {
        displayModeBar: true,
        responsive: true,
        scrollZoom: true
    }

getPlot = () ->
    $('#stockPlot')[0]
