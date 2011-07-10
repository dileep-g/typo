class XmlController < ApplicationController
  caches_page :feed, :if => Proc.new {|c|
    c.request.query_string == ''
  }

  NORMALIZED_FORMAT_FOR = {'atom' => 'atom', 'rss' => 'rss',
    'atom10' => 'atom', 'atom03' => 'atom', 'rss20' => 'rss',
    'googlesitemap' => 'googlesitemap', 'rsd' => 'rsd' }

  CONTENT_TYPE_FOR = { 'rss' => 'application/xml',
    'atom' => 'application/atom+xml',
    'googlesitemap' => 'application/xml' }

  AVAILABLE_TYPES = ['feed', 'comments', 'article', 'category', 'tag', 'author',
    'trackbacks', 'sitemap']

  before_filter :adjust_format

  def feed
    @format = params[:format]

    unless @format
      return render(:text => 'Unsupported format', :status => 404)
    end

    unless AVAILABLE_TYPES.include? params[:type]
      return render(:text => 'Unsupported action', :status => 404)
    end

    # TODO: Move redirects into config/routes.rb, if possible
    case params[:type]
    when 'feed'
      redirect_to :controller => 'articles', :action => 'index', :format => @format, :status => 301
    when 'comments'
      head :moved_permanently, :location => admin_comments_url(:format => @format)
    when 'article'
      head :moved_permanently, :location => Article.find(params[:id]).permalink_by_format(@format)
    when 'category', 'tag', 'author'
      head :moved_permanently, \
        :location => self.send("#{params[:type]}_url", params[:id], :format => @format)
    else
      @items = Array.new
      @blog = this_blog
      # We use @feed_title.<< to destructively modify @feed_title, below, so
      # make sure we have our own copy to modify.
      @feed_title = this_blog.blog_name.dup
      @link = this_blog.base_url
      @self_url = url_for(params)

      self.send("prep_#{params[:type]}")

      # TODO: Use templates from articles controller.
      respond_to do |format|
        format.googlesitemap
        format.atom
        format.rss
      end
    end
  end

  # TODO: Move redirects into config/routes.rb, if possible
  def articlerss
    redirect_to :action => 'feed', :format => 'rss', :type => 'article', :id => params[:id]
  end

  def commentrss
    redirect_to :action => 'feed', :format => 'rss', :type => 'comments'
  end

  def trackbackrss
    redirect_to :action => 'feed', :format => 'rss', :type => 'trackbacks'
  end

  def rsd

  end

  protected

  def adjust_format
    if params[:format]
      params[:format] = NORMALIZED_FORMAT_FOR[params[:format]]
    else
      params[:format] = 'rss'
    end
    request.format = params[:format] if params[:format]
    return true
  end

  def fetch_items(association, order='published_at DESC', limit=nil)
    if association.instance_of?(Symbol)
      association = association.to_s.singularize.classify.constantize
    end
    limit ||= this_blog.limit_rss_display
    @items += association.find_already_published(:all, :limit => limit, :order => order)
  end

  def prep_trackbacks
    fetch_items(:trackbacks)
    @feed_title << " trackbacks"
  end

  def prep_sitemap
    fetch_items(:articles, 'created_at DESC', 1000)
    fetch_items(:pages, 'created_at DESC', 1000)
    @items += Category.find_all_with_article_counters(1000) unless this_blog.unindex_categories
    @items += Tag.find_all_with_article_counters(1000) unless this_blog.unindex_tags
  end
end
