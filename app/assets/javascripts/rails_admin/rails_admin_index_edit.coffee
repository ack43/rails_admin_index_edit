$(document).delegate "form#index_edit_form tr[data-object-id] td .value_block", "click", (e)->
  e.preventDefault()
  form = $("form#index_edit_form")
  value_block = $(e.currentTarget)
  input_block = value_block.siblings('.input_block')
  $(".value_block", form).show()
  $(".input_block", form).hide().addClass('hidden')
  $(':input', form.find('table')).addClass('non_serializeable')
  value_block.hide()
  input_block.show().removeClass('hidden')
  input_block.closest("tr").find('.id_field').removeClass('non_serializeable')
  input = input_block.find(':input')
  input.removeClass('non_serializeable').focus().data('old-value', input.val())
  return false




$(document).delegate "form#index_edit_form tr[data-object-id] td :input", "blur", (e)->
  input = $(e.currentTarget)
  cell = input.closest('td')
  form = $("form#index_edit_form")
  data = form.find(':input:not(.non_serializeable)').serialize()

  unless input.val() == input.data('old-value')
    input.attr('readonly', 'readonly')

    $.post form.attr('action'), data, (resp, status_code, xhr)->
      _content = $(resp).find('#cell_content')
      cell.html(_content.html()).attr('title', _content.attr('title'))

    .fail (resp, status_code, xhr)->
      cell.find('.value_block').click()

    .always (resp, status_code, xhr)->
      input.removeAttr('readonly')

  $(".value_block", form).show()
  $(".input_block", form).hide().addClass('hidden')
  $(':input', form.find('table')).addClass('non_serializeable')


$(document).delegate "form#index_edit_form tr[data-object-id] td :input", "keydown keyup", (e)->
  input = $(e.currentTarget)
  if e.which == 13
    input.blur()
  else
    if e.which == 27
      input.val(input.data('old-value')).blur()
