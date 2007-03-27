# The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

module CASServer::Views

  # need to turn off autovalidation to render CAS xml responses
  #

  def layout
    # wrap as XHTML only when auto_validation is on, otherwise pass right through
    if @auto_validation
      xhtml_strict do
        head do 
          title { "#{organization} Central Login" }
          link(:rel => "stylesheet", :type => "text/css", :href => "/themes/cas.css")
          link(:rel => "stylesheet", :type => "text/css", :href => "/themes/#{current_theme}/theme.css")
        end
        body(:onload => "if (document.getElementById('username')) document.getElementById('username').focus()") do
          self << yield 
        end
      end
    else
      self << yield
    end
  end


  # 2.1.3
  def login
    table(:id => "login-box") do
      tr do
        td(:colspan => 2) do
          div(:id => "headline-container") do
            strong organization
            text " Central Login"
          end
        end
      end
      if @message
        tr do
          td(:colspan => 2, :id => "messagebox-container") do
            div(:class => "messagebox #{@message[:type]}") { @message[:message] }
          end
        end
      end
      tr do
        td(:id => "logo-container") do
          img(:id => "logo", :src => "/themes/#{current_theme}/logo.png")
        end
        td(:id => "login-form-container") do
          form(:method => "post", :action => "/login", :id => "login-form",
              :onsubmit => "submit = document.getElementById('login-submit'); submit.value='Please wait...'; submit.disabled=true; return true;") do
            table(:id => "form-layout") do
              tr do
                td(:id => "username-label-container") do
                  label(:id => "username-label", :for => "username") { "Username" }
                end
                td(:id => "username-container") do
                  input(:type => "text", :id => "username", :name => "username", :size => "32", :tabindex => "1", :accesskey => "n")
                end
              end
              tr do
                td(:id => "password-label-container") do
                  label(:id => "password-label", :for => "password") { "Password" }
                end
                td(:id => "password-container") do
                  input(:type => "password", :id => "password", :name => "password", :size => "32", :tabindex => "2", :accesskey => "p")
                end
              end
              tr do
                td{}
                td(:id => "submit-container") do
                  input(:type => "hidden", :id => "lt", :name => "lt", :value => @lt)
                  input(:type => "hidden", :id => "service", :name => "service", :value => @service)
                  input(:type => "hidden", :id => "warn", :name => "warn", :value => @warn)
                  input(:type => "submit", :class => "button", :accesskey => "l", :value => "LOGIN", :tabindex => "4", :id => "login-submit")
                end
              end
              tr do
                td(:colspan => 2, :id => "infoline") { infoline }
              end
            end
          end
        end
      end
    end
  end
  
  # 2.4.2
  def validate
    @auto_validation = false
    if @success
      text "yes\n#{@username}\n"
    else
      text "no\n\n"
    end
  end
  
  # 2.5.2
  def service_validate
    @auto_validation = false
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username.to_s.to_xs}
          if @pgtiou
            tag!("cas:proxyGrantingTicket") {@pgtiou.to_s.to_xs}
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end
  
  # 2.6.2
  def proxy_validate
    @auto_validation = false
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username.to_s.to_xs}
          if @pgtiou
            tag!("cas:proxyGrantingTicket") {@pgtiou.to_s.to_xs}
          end
          if @proxies && !@proxies.empty?
            tag!("cas:proxies") do
              @proxies.each do |proxy_url|
                tag!("cas:proxy") {proxy_url.to_s.to_xs}
              end
            end
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end
  
  # 2.7.2
  def proxy
    @auto_validation = false
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxySuccess") do
          tag!("cas:proxyTicket") {@pt.to_s.to_xs}
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxyFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end
  
  def configure
  end
  
  protected
  def themes_dir
    File.dirname(File.expand_path(__FILE__))+'../themes'
  end
  module_function :themes_dir
  
  def current_theme
    CASServer::Conf.theme || "simple"
  end
  module_function :current_theme
  
  def organization
    CASServer::Conf.organization || ""
  end
  module_function :organization
  
  def infoline
    CASServer::Conf.infoline || ""
  end
  module_function :infoline
end
