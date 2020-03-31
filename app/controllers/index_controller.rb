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

    def computation()
        @filteredIndexes.each do |symbol|
            # Compute total difference
            @qData[symbol]['diff'] = @qData[symbol]['dataset_data']['data'][0][1] - @qData[symbol]['dataset_data']['data'][-1][1]
        end
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
