module ApplicationHelper
  # Render a simple pagination nav for a Pagy::Offset instance
  def pagy_nav(pagy)
    return "" unless pagy.pages > 1

    links = []
    links << (pagy.previous ? link_to("← Prev", url_for(page: pagy.previous),
                                      class: "px-3 py-1 rounded text-sm",
                                      style: "background-color: #3c3836; color: #83a598;")
                             : content_tag(:span, "← Prev", class: "px-3 py-1 rounded text-sm opacity-30",
                                           style: "color: #a89984;"))

    pagy.series.each do |item|
      case item
      when Integer
        links << link_to(item, url_for(page: item),
                         class: "px-3 py-1 rounded text-sm",
                         style: "background-color: #3c3836; color: #ebdbb2;")
      when String
        links << content_tag(:span, item.to_i,
                             class: "px-3 py-1 rounded text-sm",
                             style: "background-color: #fe8019; color: #282828;")
      when :gap
        links << content_tag(:span, "…", style: "color: #a89984;")
      end
    end

    links << (pagy.next ? link_to("Next →", url_for(page: pagy.next),
                                  class: "px-3 py-1 rounded text-sm",
                                  style: "background-color: #3c3836; color: #83a598;")
                        : content_tag(:span, "Next →", class: "px-3 py-1 rounded text-sm opacity-30",
                                      style: "color: #a89984;"))

    content_tag(:nav, links.join(" ").html_safe,
                class: "flex items-center gap-1 mt-4",
                "aria-label": "Pagination")
  end
end
