module ApplicationHelper
  def report_link(ticket_no)
    base_link = ENV['TEST_TICKET_URL']
    link_to ticket_no, "#{base_link}#{ticket_no}/report", target: '_blank'
  end

  def new_link(text, path, hide_text='')
    link_to path, class: 'text-body' do
          content_tag(:i, '', title: text, class: 'bi-file-earmark-plus ms-2 me-2', style: 'font-size: 1.75rem;') +
          content_tag(:span, text, class: "#{hide_text}")
      end
  end

  def edit_link(text, path)
    link_to path, class: 'text-body' do
          content_tag(:span, text, class: 'visually-hidden',) +
          content_tag(:i, '', title: text, class: 'bi-pencil', style: 'font-size: 1.75rem;')
      end
  end

  def view_link(text, path)
    link_to path, class: 'text-body' do
      content_tag(:span, text, class: 'visually-hidden',) +
        content_tag(:i, '', title: text, class: 'bi-eye', style: 'font-size: 1.75rem;')
    end
  end

  def ticket_link(text, path)
    link_to path, class: 'text-body' do
      content_tag(:span, text, class: 'visually-hidden',) +
        content_tag(:i, '', title: text, class: 'bi-map', style: 'font-size: 2rem;')
    end
  end

  def new_user_link(text, path)
    link_to path, class: 'text-body' do
          content_tag(:i, '', title: text, class: 'bi-person-add', style: 'font-size: 1.75rem;') +
          content_tag(:span, text, class: 'ms-2')
      end
  end


  def users_link(text, path)
    link_to path, class: 'text-body' do
          content_tag(:span, text, class: 'visually-hidden',) +
          content_tag(:i, '', title: text, class: 'bi-person', style: 'font-size: 1.75rem;')
      end
  end

  def delete_link(text, path, msg)
    link_to path, class: 'text-body',
      data: { turbo: true, turbo_method: :delete,
              turbo_confirm: msg } do
          content_tag(:span, text, class: 'visually-hidden',) +
          content_tag(:i, '', title: text, class: 'bi-trash ms-2', style: 'font-size: 1.75rem;')
      end
  end
end
