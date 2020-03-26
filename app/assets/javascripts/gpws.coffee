# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

main = () ->
    lData = $('#ldata').data('ldata')

    lDataPlot = getPlot()

    # plotLinear(lDataPlot, lData)
    plotCandel(lDataPlot, lData)

window.onload = main

plotCandel = (_plt, _ld) ->

    _date = (row.date for row in _ld)
    _open = (row.open for row in _ld)
    _high = (row.high for row in _ld)
    _low = (row.low for row in _ld)
    _close = (row.close for row in _ld)

    _d = {
        x: _date,
        open: _open,
        high: _high,
        low: _low,
        close: _close,
        type: 'candlestick'
    }

    Plotly.newPlot(_plt, [_d])

plotLinear = (_plt, _ld) ->

    _x = (row.date for row in _ld)
    _y = (row.close for row in _ld)

    Plotly.newPlot(
        _plt,
        [{
            x:_x,
            y:_y
        }]
    )

getPlot = () ->
    $('#stockPlot')[0]
