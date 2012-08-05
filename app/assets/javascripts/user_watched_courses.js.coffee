$ ->

  $form = $("form#user_watched_course_create")
  if $form.length
    $local = (selector) -> $form.find(selector)
    error = (msg) -> $local(".alert").html(msg).removeClass("hide")
    clearError = -> $local(".alert").html("")
    
    $form.submit (event) ->
      event.preventDefault()
      if $form.attr("submitting")?
        return
      $form.attr("submitting", "")
      ccn = $local("input[name=ccn]").val()
      monitor_type = $local("input[name=monitor_type]").val()
      if not ccn.match /^\d{5}$/
        error "ccn format incorrect (must consist of exactly 5 digits)"
        $form.removeAttr("submitting")
        return
      $.ajax(
        url: $$url['watch_course']
        type: "POST"
        data: {ccn: ccn, monitor_type: monitor_type}
        dataType: 'json'
        success: (data, status, xhr) ->
          clearError()
          location.reload()
        error: (xhr, status, e) ->
          data = JSON.parse(xhr.responseText)
          error_msg = ""
          for entry, messages of data
            for message in messages
              error_msg += "#{entry} #{message}.<br>"
          error error_msg
        beforeSend: ->
          $local(".form-info").html("checking course info...")
      ).always ->
        $local(".form-info").html("")
        $form.removeAttr("submitting")
