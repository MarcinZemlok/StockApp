require 'dotenv/load'
require 'httparty'

$finnhubToken = ENV['FINNHUB_KEY']
$quandlToken = ENV['QUANDL_KEY']

class IndexController < ApplicationController
    def index
        # @symbols = fetchSymbols

        # @trackSymbols = {
        #     'ENT.WA'=>{},
        #     'RBW.WA'=>{}
        # }
        # fetchQuote

        # @recommendations = {
        #     'ENT.WA'=>{},
        #     'RBW.WA'=>{}
        # }
        # fetchRecommendations

        # @TODAY = Time.new

        # @qData = {}
        # @filteredIndexes = $allIndexes[0..0]
        # fetchQuandle
        # computation
        # sort('diff')
    end

    def fetchQuandle
        # return if not stockOpen
        return if stockOpen

        @filteredIndexes.each do |symbol|
            @qData[symbol] = {}
            @qData[symbol][:calcs] = {}

            if(fetchRequired(symbol))
                @qData[symbol][:meta] = fetchMeta(symbol)['dataset']
                calculateLastUpdatedSpan(symbol, @qData[symbol][:meta]['refreshed_at'])
                assesTimespan(symbol)
                @qData[symbol][:data] = fetchData(symbol)['dataset_data']
                saveData(symbol, @qData[symbol][:data]['data'])
            end
        end
    end

    def fetchRequired(_index)
        _record = Gpw.exists?({
            index: _index,
            date: @TODAY
        })

        mylog("[#{_index}] Fetch required") if not _record

        return (not _record)
    end

    def fetchMeta(_index)
        url = "https://www.quandl.com/api/v3/datasets/WSE/#{_index}/metadata.json?api_key=#{$quandlToken}"

        res = HTTParty.get(url)

        return JSON.parse(res.body)
    end

    def fetchData(_index)
        url = "https://www.quandl.com/api/v3/datasets/WSE/#{_index}/data.json?api_key=#{$quandlToken}&limit=100"

        res = HTTParty.get(url)

        return JSON.parse(res.body)
    end

    def saveData(_index, _data)
        standarizeColumns(_index)
        _columns = @qData[_index][:meta]['column_names']

        _data.each do |_d|
            _time = Time.new(_d[0][0..3], _d[0][5..6], _d[0][8..9])
            _record = Gpw.exists?({
                index: _index,
                date: _time
            })

            _date = _d[_columns.index('date')] if _columns.index('date')
            _open = _d[_columns.index('open')] if _columns.index('open')
            _high = _d[_columns.index('high')] if _columns.index('high')
            _low = _d[_columns.index('low')] if _columns.index('low')
            _close = _d[_columns.index('close')] if _columns.index('close')
            _change = _d[_columns.index('change')] if _columns.index('change')
            _volume = _d[_columns.index('volume')] if _columns.index('volume')
            _trades = _d[_columns.index('trades')] if _columns.index('trades')
            _tornover = _d[_columns.index('turnover')] if _columns.index('turnover')

            _tmp = Gpw.new({
                :index => _index,
                :date => _date,
                :open => _open,
                :high => _high,
                :low => _low,
                :close => _close,
                :change => _change,
                :volume => _volume,
                :trades => _trades,
                :tornover => _tornover,
            }) if not _record

            _tmp.save if not _record
        end
    end

    def calculateLastUpdatedSpan(_index, _last)
        _lt = Time.new(_last[0..3], _last[5..6], _last[8..9])

        _calcs = @qData[_index][:calcs]
        _calcs[:update_span_s] = (Time.new - _lt).floor
        _calcs[:update_span_d] = (_calcs[:update_span_s]/86400).floor
        _calcs[:update_span_w] = (_calcs[:update_span_d]/7).floor
    end

    def assesTimespan(_index)
        _calcs = @qData[_index][:calcs]
        _calcs[:alive] = _calcs[:update_span_w] < 4
    end

    def stockOpen
        _saturday = @TODAY.strftime('%u') != '6'
        _sunday = @TODAY.strftime('%u') != '7'

        mylog("[WARNING] Stock is closed (#{@TODAY.strftime('%A')})") if _saturday or _sunday

        return (not _saturday and not _sunday)
    end

    def standarizeColumns(_index)
        _columns = @qData[_index][:meta]['column_names']
        _i = 0
        _columns.each do |c|
            _columns[_i] = 'open' if 'Open'.in? c
            _columns[_i] = 'close' if 'Close'.in? c
            _columns[_i] = 'high' if 'High'.in? c
            _columns[_i] = 'low' if 'Low'.in? c
            _columns[_i] = 'date' if 'Date'.in? c
            _columns[_i] = 'change' if 'Change'.in? c
            _columns[_i] = 'volume' if 'Volume'.in? c
            _columns[_i] = 'trades' if 'Trades'.in? c
            _columns[_i] = 'turnover' if 'Turnover'.in? c

            _i+=1
        end

    end

    def computation()
        @filteredIndexes.each do |symbol|
            # Compute total difference
            @qData[symbol]['diff'] = @qData[symbol]['dataset_data']['data'][0][1] - @qData[symbol]['dataset_data']['data'][-1][1]
        end
    end

    def sort(_by, _how='ASCENDING')
        # Simple sorting mechanism
        for i in (0...@filteredIndexes.length)
            for j in (0...@filteredIndexes.length)
                _a = @qData[@filteredIndexes[i]][_by]
                _b = @qData[@filteredIndexes[j]][_by]

                _swap = false
                case _how
                when 'ASCENDING'
                    _swap = (_a < _b)
                when 'DECENDING'
                    _swap = (_a > _b)
                end

                if(_swap)
                    @filteredIndexes[i], @filteredIndexes[j] =
                    @filteredIndexes[j], @filteredIndexes[i]
                end
            end
        end
    end

    def mylog(_str)
        puts "\e[38:5:0m\e[48:5:15m#{_str}\e[m"
    end

    def fetchSymbols()
        res = HTTParty.get("https://finnhub.io/api/v1/stock/symbol?exchange=WA&token=#{$finnhubToken}")

        puts "Symbols fetch: #{res.code}"

        return JSON.parse(res.body)
    end

    def fetchQuote()
        @trackSymbols.keys.each do |symbol|
            s = symbol[0..2]
            res = HTTParty.get("https://finnhub.io/api/v1/quote?symbol=#{s}&token=#{$finnhubToken}")

            puts "Quotes fetch: #{res.code}"

            @trackSymbols[symbol] = JSON.parse(res.body)
        end
    end

    def fetchRecommendations()
        @trackSymbols.keys.each do |symbol|
            s = symbol[0..2]
            res = HTTParty.get("https://finnhub.io/api/v1/stock/recommendation?symbol=#{s}&token=#{$finnhubToken}")

            puts "Recommendations fetch: #{res.code}"

            @recommendations[symbol] = JSON.parse(res.body)
        end
    end
end
