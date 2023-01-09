class Blog < ActiveRecord::Base
  belongs_to :categories, optional: true
  after_create :update_jobs

  def update_jobs
    if self.blog_url.present? && self.source_website == 'kanxue'
    UpdateKanxueBlogUsingProxyJob.perform_later blog: self
    elsif self.blog_url.present? && self.source_website == 'xianzhi'
    UpdateXianzhiBlogUsingProxyJob.perform_later blog: self
    end
  end
end
