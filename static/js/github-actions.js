jQuery(function(){
    var escapeHTML = function(string) {
        // Lifted from mustache.js
        var entityMap = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': '&quot;',
            "'": '&#39;',
            "/": '&#x2F;'
        };
        return string.replace(/[&<>"'\/]/g, function(s) {
            return entityMap[s];
        });
    };

    var template = '<div class="form-row"><div class="label col-3">Status:</div><div class="value col-9"><a href="{{ title_url }}""><span class="github-actions-status-{{ last_build_state }}">{{ pretty_build_state }}</span></a></div></div>';

    var template_short = '<div><a href="{{ title_url }}""><span class="github-actions-status-{{ last_build_state }}">{{ pretty_build_state }}</span></a></div>';

    var github_actions_fetch = function(template) {
        var _ = this;
        var ticket_id = jQuery(this).attr("data-github-actions-ticketid");
        jQuery.getJSON(
            RT.Config.WebPath + "/Helpers/Github/ActionsStatus?id=" + ticket_id,
            function(data) {
                if (data == null) return;
                if (!data.success) {
                    jQuery(_).html(escapeHTML(data.error));
                    return;
                }
                data = data.result;
                var title_url = data.title_url;
                var last_build_state = data.last_build.state;
                var pretty_build_state = data.last_build.pretty_build_state;
                jQuery(_).html(template.replace(
                    /{{\s*(.+?)\s*}}/g,
                    function(m,code){
                        return escapeHTML(eval(code));
                    }
                ));
            }
        );
    };

    jQuery(".ticket-summary .github-actions").each(function(){
        github_actions_fetch.call(this, template);
    });

    jQuery(".ticket-list .github-actions").each(function(){
        github_actions_fetch.call(this, template_short);
    });

});
