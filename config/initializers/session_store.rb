Rails.application.config.session_store :cookie_store,
                                       key: "_fvadmin",
                                       same_site: :lax,
                                       expire_after: 60.minutes
