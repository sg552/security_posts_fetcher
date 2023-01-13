class Blog < ActiveRecord::Base
  belongs_to :categories, optional: true
  after_commit :update_jobs, on: :create

  def update_jobs
    if self.blog_url.present? && self.source_website == 'kanxue' && self.content.blank?
      if self.blog_url.include? 'article'
        UpdateKanxueBlogUsingProxyJob.perform_later blog: self
      else
        UpdateKanxueBlogUsingPlaywrightJob.perform_later blog: self
      end
    elsif self.blog_url.present? && self.source_website == 'xianzhi' && self.content.blank?
      UpdateXianzhiBlogUsingProxyJob.perform_later blog: self
    end
  end

end
