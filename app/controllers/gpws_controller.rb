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
    end

    def update
        if params[:fetch_new] == 'true'
            fetchQuandleNew(params[:id])
        else
            fetchQuandleOld(params[:id])
        end

        redirect_to action: "show", id: params[:id]
    end

end
