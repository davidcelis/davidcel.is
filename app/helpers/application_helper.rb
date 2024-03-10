module ApplicationHelper
  include Pagy::Frontend

  def profile_picture_url
    @profile_picture_url ||= if christmas?
      asset_url("santa.jpg")
    else
      asset_url("me.jpg")
    end
  end

  def let_it_snow(&)
    if christmas?
      content_tag("snow-fall", &)
    else
      yield
    end
  end

  def profile_picture_alt_text
    @profile_picture_alt_text ||= if christmas?
      "A photo of me wearing a blue blazer and pocket square while on a horse, looking quite dapper. Both me and the horse are wearing Santa hats."
    else
      "A photo of me wearing a blue blazer and pocket square while on a horse, looking quite dapper."
    end
  end

  def profile_title
    @profile_title ||= if christmas?
      "🎵 Celiz Davidad 🎶"
    else
      "David Celis"
    end
  end

  def profile_subtitle
    @profile_subtitle ||= if christmas?
      "Próspero año y felicidad!"
    else
      "A cowboy coder."
    end
  end

  def christmas?
    @christmas ||= Date.today.month == 12 || (Date.today.month == 1 && Date.today.day == 1)
  end
end
