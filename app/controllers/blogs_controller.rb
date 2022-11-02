class BlogsController < ApplicationController
  before_action :set_blog, only: [:show, :edit, :update, :destroy]

  def index
    @blogs = Blog.all
    @blogs = @blogs.where('content like ?', "%#{params[:blog_content]}%") if params[:blog_content].present?
    @blogs = @blogs.where('title like ?', "%#{params[:blog_title]}%") if params[:blog_title].present?
    @blogs = @blogs.where('source_website like ?', "%#{params[:blog_source_website]}%") if params[:blog_source_website].present?
    @total_count = @blogs.all.size
    @blogs = @blogs.order('id desc').page(params[:page]).per(100)
  end

  def show
  end

  def new
  end

  def edit
  end

  def create
    @blog = Blog.new(blog_params)
    if @blog.save
      redirect_to @blog, notice: '操作成功'
    else
      render :new
    end
  end

  def update
    if @blog.update(blog_params)
      redirect_to @blog, notice: '操作成功'
    else
      render :edit
    end
  end


  def destroy
    @blog.destroy
    redirect_to blogs_url, notice: '操作成功'
  end

  private
    def set_blog
      @blog = Blog.find(params[:id])
    end
end
