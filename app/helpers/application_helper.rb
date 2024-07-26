module ApplicationHelper
  def edit_link(path, text)
    link_to path, class: 'text-body' do
          content_tag(:span, text, class: 'visually-hidden',) +
          content_tag(:i, '', title: text, class: 'bi-pencil', style: 'font-size: 2rem;')
      end
  end

  def delete_link(path, text, msg)
    link_to path, class: 'text-body',
      data: { turbo: true, turbo_method: :delete,
              turbo_confirm: msg } do
          content_tag(:span, text, class: 'visually-hidden',) +
          content_tag(:i, '', title: text, class: 'bi-trash', style: 'font-size: 2rem;')
      end
  end
end
