module CommunityUsersHelper

  def user_activity_distribution(community)
    start_date = community.created_at
    end_date = community.task_occurrences.order(:created_at).last.try(:created_at) || Time.now
    time_range = (start_date.to_i..end_date.to_i).step(1.month.to_i).map {|i| Time.at(i).to_date.beginning_of_month}.uniq
    
    query_result = community.task_occurrences.select("user_id, max(created_at) as date, sum(time_in_minutes) as total").group("date_trunc('month', created_at), date_trunc('year', created_at), user_id")
    
    time_range.map do |date|
      date_occurrences = query_result.select {|o| o.date.to_time.beginning_of_month == date}
        if date_occurrences.any?
          time_per_user = date_occurrences.map {|task_occurrence| {task_occurrence.user.name => task_occurrence.total}}.inject {|all, h| all.merge h}
          {date: date}.merge time_per_user
        else
          {date: date} 
        end  
    end.to_json
  end

  private
    def determine_interval_for(start_date, end_date)
      date_diff = end_date - start_date

      if date_diff > 5.year
        6.month
      elsif date_diff > 2.year
        1.month
      elsif date_diff > 6.month
        1.week
      else
        1.day
      end
    end
end
