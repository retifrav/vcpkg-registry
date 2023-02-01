_find_package(${ARGS})

if(APPLE)
    if(TARGET XercesC::XercesC)
        set_target_properties(XercesC::XercesC
            PROPERTIES
                INTERFACE_LINK_LIBRARIES
                    "-framework CoreServices"
                    #"-framework CoreFoundation"
                    # and also cURL, if network is enabled
        )
        list(APPEND XercesC_LIBRARIES
            "-framework CoreServices"
            #"-framework CoreFoundation"
            # and also cURL, if network is enabled
        )
    endif()
endif()
