import Foundation

/// The tables that say which query parameter of a URL is a tracker.
///
/// A tracker carries no information for the page. It tells the owner of the site
/// who sent you and which advertisement you saw. The application removes it.
///
/// Two tables exist, because a short name is dangerous. `s` is a tracker on
/// `x.com` and a search term on many other sites. A short name therefore goes
/// into a host rule, never into the global table.
enum TrackingParameters {
    /// A name that is a tracker on every site. Every entry is lower case.
    static let globalNames: Set<String> = [
        // Google Ads and Google Analytics.
        "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "gad_source",
        "gad_campaignid", "gcl_au", "gclid_source", "srsltid", "ncid",
        "gs_l", "gad", "gaa_at", "gaa_n", "gaa_sig", "gaa_ts",
        // Microsoft, Yandex, Baidu.
        "msclkid", "yclid", "ymclid", "yandex_clid", "_openstat", "bd_vid",
        // The social networks.
        "fbclid", "fb_action_ids", "fb_action_types", "fb_source", "fb_ref",
        "fbadid", "fbc", "fbp", "twclid", "ttclid", "li_fat_id", "igshid",
        "igsh", "epik", "rdt_cid", "guccounter", "guce_referrer",
        "guce_referrer_sig", "__twitter_impression", "sc_click_id",
        // The affiliate networks.
        "irclickid", "irgwc", "zanpid", "ranmid", "raneaid", "ransiteid",
        "clickid", "cjevent", "cjdata", "partnerid", "affiliate_id",
        "impression_id", "click_id", "rb_clickid",
        // The e-mail platforms.
        "mc_cid", "mc_eid", "mkt_tok", "vero_conv", "vero_id", "ck_subscriber_id",
        "ml_subscriber", "ml_subscriber_hash", "omnisendattributionid",
        "oly_anon_id", "oly_enc_id", "__s", "sb_referer_host", "s_cid",
        "elqtrackid", "elq", "elqaid", "elqat", "elqcampaignid",
        "redirect_log_message", "redirect_mongo_id", "vgo_ee",
        // HubSpot.
        "_hsenc", "_hsmi", "__hssc", "__hstc", "__hsfp", "hsctatracking",
        // Adobe and AT Internet.
        "s_kwcid", "ef_id", "xtor", "wt.mc_id", "wt.tsrc", "wt_zmc", "wt_mc",
        // The news sites.
        "ns_campaign", "ns_mchannel", "ns_source", "ns_linkname", "ns_fee",
        "cmpid", "cmp", "intcmp", "ito", "icid", "smid", "smtyp",
        "wpisrc", "wpmm", "tid", "itid",
        // The rest.
        "soc_src", "soc_trk", "trk_contact", "trk_module", "trk_sid",
        "wickedid", "wickedsource", "wickedpicked", "otc", "_branch_match_id",
        "_branch_referrer", "hmb_campaign", "hmb_medium", "hmb_source",
        "gdfms", "gdftrk", "gdffi", "sc_campaign", "sc_channel", "sc_content",
        "sc_medium", "sc_outcome", "sc_geo", "sc_country", "sc_customer",
        "nb_klid", "gs_lcrp",
    ]

    /// A family of names. `utm_source`, `utm_medium` and every other `utm_` name
    /// go with one entry. Every entry is lower case.
    static let globalPrefixes: [String] = [
        "utm_",     // Google Analytics, and now the whole industry.
        "pk_",      // Piwik.
        "mtm_",     // Matomo.
        "matomo_",
        "piwik_",
        "hsa_",     // HubSpot Ads.
        "sfmc_",    // Salesforce Marketing Cloud.
        "itm_",     // The Guardian.
        "at_custom",
        "spm_",
    ]

    /// The rules of one site.
    struct HostRule: Sendable {
        /// The host, or the parent of the host. `x.com` also matches
        /// `mobile.x.com`.
        let hosts: [String]
        let names: Set<String>
        var prefixes: [String] = []
    }

    /// Every entry is lower case.
    static let hostRules: [HostRule] = [
        HostRule(
            hosts: ["x.com", "twitter.com"],
            names: ["s", "t", "ref_src", "ref_url", "cxt", "cn"]
        ),
        HostRule(
            hosts: ["facebook.com", "fb.com", "fb.watch"],
            names: ["refsrc", "hrc", "ref", "dti", "app", "video_source",
                    "comment_tracking", "notif_id", "notif_t", "rdid",
                    "share_url_id", "acontext"],
            prefixes: ["__tn__", "__cft__", "__xts__"]
        ),
        HostRule(
            hosts: ["instagram.com"],
            names: ["igshid", "igsh"]
        ),
        HostRule(
            hosts: ["tiktok.com"],
            names: ["_t", "_r", "_d", "checksum", "share_app_id",
                    "share_item_id", "share_link_id", "sec_user_id", "tt_from",
                    "source", "u_code", "timestamp", "user_id", "enter_from",
                    "enter_method", "is_from_webapp", "sender_device", "web_id",
                    "refer", "referer_url", "referer_video_id"]
        ),
        HostRule(
            hosts: ["youtube.com", "youtu.be", "music.youtube.com"],
            names: ["si", "feature", "kw", "ab_channel"]
        ),
        HostRule(
            hosts: ["spotify.com"],
            names: ["si", "nd", "_branch_match_id"]
        ),
        HostRule(
            hosts: ["reddit.com", "redd.it"],
            names: ["share_id", "correlation_id", "ref", "ref_source", "rdt",
                    "post_fullname", "chainedposts"]
        ),
        HostRule(
            hosts: ["linkedin.com"],
            names: ["trackingid", "refid", "midtoken", "midsig", "trk",
                    "trkemail", "originalsubdomain", "lipi", "licu", "ebp",
                    "eid", "otptoken"]
        ),
        HostRule(
            hosts: ["amazon.com", "amazon.co.uk", "amazon.de", "amazon.fr",
                    "amazon.it", "amazon.es", "amazon.ca", "amazon.co.jp",
                    "amazon.com.au", "amazon.in", "amazon.com.br", "amazon.nl",
                    "amazon.se", "amazon.pl", "amazon.com.mx", "amzn.to"],
            names: ["ref", "psc", "tag", "dib", "dib_tag", "content-id", "qid",
                    "sr", "sprefix", "crid", "linkcode", "linkid", "camp",
                    "creative", "creativeasin", "ascsubtag", "smid", "ie"],
            prefixes: ["ref_", "pf_rd_", "pd_rd_", "_encoding"]
        ),
        HostRule(
            hosts: ["ebay.com", "ebay.co.uk", "ebay.de", "ebay.it", "ebay.fr",
                    "ebay.es", "ebay.com.au", "ebay.ca"],
            names: ["_trkparms", "_trksid", "mkcid", "mkrid", "campid",
                    "toolid", "customid", "mkevt", "siteid", "amdata", "var"]
        ),
        HostRule(
            hosts: ["aliexpress.com", "aliexpress.us"],
            names: ["spm", "scm", "scm_id", "scm-url", "pvid", "algo_pvid",
                    "algo_expid", "btsid", "ws_ab_test", "gatewayadapt", "sk",
                    "aff_fcid", "aff_fsk", "aff_platform", "aff_trace_key",
                    "terminal_id", "curpageloguid", "_randstr"]
        ),
        HostRule(
            hosts: ["etsy.com"],
            names: ["click_key", "click_sum", "ref", "frs", "sts",
                    "organic_search_click", "bes", "content_source"]
        ),
        HostRule(
            hosts: ["walmart.com"],
            names: ["athbdg", "athcpid", "athcgid", "athznid", "athieid",
                    "athstid", "athguid", "athancid", "athena", "from"]
        ),
        HostRule(
            hosts: ["google.com", "google.co.uk", "google.de", "google.it",
                    "google.fr", "google.es", "news.google.com"],
            names: ["ved", "ei", "gs_lcp", "gs_lp", "sca_esv", "sclient", "oq",
                    "uact", "sourceid", "source", "bih", "biw", "dpr",
                    "iflsig", "sxsrf", "gs_ssp", "sa", "usg"]
        ),
        HostRule(
            hosts: ["pinterest.com", "pin.it"],
            names: ["nic", "nic_v1", "nic_v2", "sender", "invite_code"]
        ),
        HostRule(
            hosts: ["medium.com"],
            names: ["source", "sk", "gi"]
        ),
        HostRule(
            hosts: ["imdb.com"],
            names: ["ref_", "pf_rd_p", "pf_rd_r"]
        ),
        HostRule(
            hosts: ["booking.com"],
            names: ["aid", "label", "sb_price_type", "srepoch", "dest_type"]
        ),
        HostRule(
            hosts: ["airbnb.com", "airbnb.co.uk", "airbnb.it"],
            names: ["source_impression_id", "federated_search_id",
                    "previous_page_section_name", "search_mode"]
        ),
        HostRule(
            hosts: ["stackoverflow.com", "stackexchange.com"],
            names: ["r", "rq"]
        ),
    ]

    /// `true` when the parameter is a tracker on this host.
    /// - Parameters:
    ///   - name: the name of the query parameter, in any case.
    ///   - host: the host of the URL, or `nil` when the URL has no host.
    static func isTracking(name: String, host: String?) -> Bool {
        let lowered = name.lowercased()

        if globalNames.contains(lowered) { return true }
        if globalPrefixes.contains(where: { lowered.hasPrefix($0) }) { return true }

        guard let host = host?.lowercased() else { return false }

        for rule in hostRules where rule.matches(host: host) {
            if rule.names.contains(lowered) { return true }
            if rule.prefixes.contains(where: { lowered.hasPrefix($0) }) { return true }
        }

        return false
    }
}

extension TrackingParameters.HostRule {
    /// `true` for the host itself and for any subdomain of it.
    func matches(host: String) -> Bool {
        hosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }
}
