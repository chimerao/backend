class JournalSharesController < SharesController

  private

    def get_shareable
      @shareable = Journal.find(params[:id])
    end

    def get_share
      @share = current_profile.shares.journals.find_by_shareable_id(@shareable.id)
    end
end
