class GpwsController < ApplicationController

    def index
    end

    def fetchLocalAll
        # $allIndexes.each do |index|
        #     @lData[index] = Gpw.where(:index=>index).order(:date).reverse_order().take(1)
        # end
    end

    def show
        @lData = Gpw.where(:index=>params[:id]).order(date: :desc)

        @bData = Tips.new(@lData)

        # mylog(@bData.inspect)
    end

    def update
        if params[:fetch_new] == 'true'
            fetchQuandleNew(params[:id]) if params[:fetch_all] == 'false'
            for _index in $allIndexes
                fetchQuandleNew(_index)
            end if params[:fetch_all] == 'true'
        else
            fetchQuandleOld(params[:id]) if params[:fetch_all] == 'false'
            for _index in $allIndexes
                fetchQuandleOld(_index)
            end if params[:fetch_all] == 'true'
        end

        redirect_to action: "index"
    end

end
