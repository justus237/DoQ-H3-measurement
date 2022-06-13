function doWhenReady(e) {
    var t = function() {
        document.removeEventListener("DOMContentLoaded", t), window.removeEventListener("load", t), e(), e = function() {}
    };
    "complete" === document.readyState ? e() : (document.addEventListener("DOMContentLoaded", t), window.addEventListener("load", t))
}

function getIso639(e) {
    var t = e && e.match(/^\w+/);
    if (t && !(3 < (t = "nb" === t[0] ? "no" : t[0]).length)) return t
}

function getDevicePixelRatio() {
    return void 0 !== window.devicePixelRatio ? window.devicePixelRatio : void 0 !== window.msMatchMedia ? window.msMatchMedia("(min-resolution: 192dpi)").matches ? 2 : window.msMatchMedia("(min-resolution: 144dpi)").matches ? 1.5 : 1 : 1
}
window.Element && !Element.prototype.matches && (Element.prototype.matches = function(e) {
    for (var t = (this.document || this.ownerDocument).querySelectorAll(e), n = t.length; 0 <= --n && t.item(n) !== this;);
    return -1 < n
}), window.attachedEvents = [], Element.prototype.matches || (Element.prototype.matches = Element.prototype.msMatchesSelector || Element.prototype.webkitMatchesSelector), Element.prototype.closest || (Element.prototype.closest = function(e) {
    var t = this;
    do {
        if (Element.prototype.matches.call(t, e)) return t;
        t = t.parentElement || t.parentNode
    } while (null !== t && 1 === t.nodeType);
    return null
});
var _ = _ || {};
_.now = Date.now || function() {
    return (new Date).getTime()
}, _.throttle = function(n, a, r) {
    var o, i, s, l = null,
        c = 0;
    r = r || {};

    function u() {
        c = !1 === r.leading ? 0 : _.now(), l = null, s = n.apply(o, i), l || (o = i = null)
    }
    return function() {
        var e = _.now();
        c || !1 !== r.leading || (c = e);
        var t = a - (e - c);
        return o = this, i = arguments, t <= 0 || a < t ? (l && (clearTimeout(l), l = null), c = e, s = n.apply(o, i), l || (o = i = null)) : l || !1 === r.trailing || (l = setTimeout(u, t)), s
    }
}, _.debounce = function(t, n, a) {
    var r, o, i, s, l, c = function() {
        var e = _.now() - s;
        e < n && 0 <= e ? r = setTimeout(c, n - e) : (r = null, a || (l = t.apply(i, o), r || (i = o = null)))
    };
    return function() {
        i = this, o = arguments, s = _.now();
        var e = a && !r;
        return r = r || setTimeout(c, n), e && (l = t.apply(i, o), i = o = null), l
    }
};
var mw = mw || {};
mw.html = function() {
        function t(e) {
            switch (e) {
                case "'":
                    return "&#039;";
                case '"':
                    return "&quot;";
                case "<":
                    return "&lt;";
                case ">":
                    return "&gt;";
                case "&":
                    return "&amp;"
            }
        }
        return {
            escape: function(e) {
                return e.replace(/['"<>&]/g, t)
            },
            element: function(e, t, n) {
                var a, r, o = "<" + e;
                for (r in t) {
                    if (!0 === (a = t[r])) a = r;
                    else if (!1 === a) continue;
                    o += " " + r + '="' + this.escape(String(a)) + '"'
                }
                if (null == n) return o += "/>";
                switch (o += ">", typeof n) {
                    case "string":
                        o += this.escape(n);
                        break;
                    case "number":
                    case "boolean":
                        o += String(n);
                        break;
                    default:
                        if (n instanceof this.Raw) o += n.value;
                        else {
                            if (!(n instanceof this.Cdata)) throw new Error("mw.html.element: Invalid type of contents");
                            if (/<\/[a-zA-z]/.test(n.value)) throw new Error("mw.html.element: Illegal end tag found in CDATA");
                            o += n.value
                        }
                }
                return o += "</" + e + ">"
            },
            Raw: function(e) {
                this.value = e
            },
            Cdata: function(e) {
                this.value = e
            }
        }
    }(), mw.storage = {
        localStorage: function() {
            try {
                return window.localStorage
            } catch (e) {}
        }(),
        get: function(e) {
            try {
                return mw.storage.localStorage.getItem(e)
            } catch (e) {}
            return !1
        },
        set: function(e, t) {
            try {
                return mw.storage.localStorage.setItem(e, t), !0
            } catch (e) {}
            return !1
        },
        remove: function(e) {
            try {
                return mw.storage.localStorage.removeItem(e), !0
            } catch (e) {}
            return !1
        }
    }, mw.RegExp = {
        escape: function(e) {
            return e.replace(/([\\{}()|.?*+\-^$[\]])/g, "\\$1")
        }
    },
    function(r, o, l, i, s, c) {
        "use strict";

        function u(e) {
            var t, n, s = this,
                a = e.length,
                r = 0,
                o = s.i = s.j = s.m = 0;
            for (s.S = [], s.c = [], a || (e = [a++]); r < l;) s.S[r] = r++;
            for (r = 0; r < l; r++) o = g(o + (t = s.S[r]) + e[r % a]), n = s.S[o], s.S[r] = n, s.S[o] = t;
            s.g = function(e) {
                var t = s.S,
                    n = g(s.i + 1),
                    a = t[n],
                    r = g(s.j + a),
                    o = t[r];
                t[n] = o, t[r] = a;
                for (var i = t[g(a + o)]; --e;) n = g(n + 1), o = t[r = g(r + (a = t[n]))], t[n] = o, t[r] = a, i = i * l + t[g(a + o)];
                return s.i = n, s.j = r, i
            }, s.g(l)
        }

        function d(e, t, n, a) {
            for (e += "", a = n = 0; a < e.length; a++) t[g(a)] = g((n ^= 19 * t[g(a)]) + e.charCodeAt(a));
            for (a in e = "", t) e += String.fromCharCode(t[a]);
            return e
        }

        function g(e) {
            return e & l - 1
        }
        o.seedrandom = function(e, t) {
            var a, n = [];
            return e = d(function e(t, n, a, r, o) {
                a = [];
                o = typeof t;
                if (n && "object" == o)
                    for (r in t)
                        if (r.indexOf("S") < 5) try {
                            a.push(e(t[r], n - 1))
                        } catch (e) {}
                return a.length ? a : t + ("string" != o ? "\0" : "")
            }(t ? [e, r] : arguments.length ? e : [(new Date).getTime(), r, window], 3), n), d((a = new u(n)).S, r), o.seededrandom = function() {
                for (var e = a.g(6), t = c, n = 0; e < i;) e = (e + n) * l, t *= l, n = a.g(1);
                for (; s <= e;) e /= 2, t /= 2, n >>>= 1;
                return (e + n) / t
            }, e
        }, c = o.pow(l, 6), i = o.pow(2, i), s = 2 * i, d(o.random(), r)
    }([], Math, 256, 52),
    window.wmTest = function(e, t) {
        var n, a, r, o, i, s, l, c, u = {
                popSize: /www.wikipedia.org/.test(location.hostname) ? 200 : 2,
                testGroups: !1,
                sessionLength: 9e5
            },
            d = "portal_session_id",
            g = "portal_test_group_expires";

        function m(e) {
            return 1 === Math.floor(Math.seededrandom() * e + 1)
        }

        function h() {
            var e = "rejected";
            return m(u.popSize) && (e = "baseline", u.testGroups && u.testGroups.test && m(10) && (e = m(2) ? u.testGroups.test : u.testGroups.control)), e
        }
        return n = function() {
            var e, t, n = [];

            function a(e) {
                var t = getIso639(e);
                t && n.indexOf(t) < 0 && n.push(t)
            }
            for (t in navigator.languages) a(navigator.languages[t]);
            return /Android/i.test(navigator.userAgent) && (e = navigator.userAgent.split(";"))[3] && a(e[3].trim()), a(navigator.language), a(navigator.userLanguage), a(navigator.browserLanguage), a(navigator.systemLanguage), n
        }(), o = location.hash.slice(1) === u.testGroups.test, c = !1, t.storage.localStorage && !/1|yes/.test(navigator.doNotTrack) && (i = t.storage.get(d), s = t.storage.get(g), l = (new Date).getTime(), i && s > parseInt(l, 10) ? c = i : (c = e.generateRandomSessionId(), t.storage.set(d, c)), t.storage.set(g, l + u.sessionLength)), (a = c) ? (Math.seedrandom(a), r = o ? u.testGroups.test : h()) : (r = "rejected", o = !0), u.testGroups && r === u.testGroups.test && (document.body.className += " " + r), {
            loggingDisabled: o,
            sessionId: a,
            userLangs: n,
            group: r,
            testGroups: u.testGroups,
            populationSize: u.popSize,
            getTestGroup: h
        }
    }(eventLoggingLite, mw),
    function(r, e) {
        "use strict";
        var o, i, t, s, n, a, l = document.cookie.match(/GeoIP=.[^:]/),
            c = document.cookie.match(/GeoIP=.[^:].{2}[^:]/);
        if ("rejected" !== e.group && !e.loggingDisabled) {
            for (o = {
                    name: "WikipediaPortal",
                    revision: 15890769,
                    defaults: {
                        session_id: e.sessionId,
                        event_type: "landing",
                        referer: document.referrer || null,
                        accept_language: e.userLangs.toString(),
                        cohort: e.group
                    },
                    properties: {
                        session_id: {
                            type: "string",
                            required: !0
                        },
                        event_type: {
                            type: "string",
                            required: !0,
                            enum: ["landing", "clickthrough", "select-language"]
                        },
                        section_used: {
                            type: "string",
                            required: !1,
                            enum: ["primary links", "search", "language search", "secondary links", "other languages", "other projects"]
                        },
                        destination: {
                            type: "string",
                            required: !1
                        },
                        referer: {
                            type: "string",
                            required: !1
                        },
                        country: {
                            type: "string",
                            required: !1
                        },
                        accept_language: {
                            type: "string",
                            required: !0
                        },
                        cohort: {
                            type: "string",
                            required: !1
                        },
                        selected_language: {
                            type: "string",
                            required: !1
                        }
                    }
                }, i = [{
                    name: "primary links",
                    nodes: document.querySelectorAll('[data-el-section="primary links"]')
                }, {
                    name: "search",
                    nodes: document.querySelectorAll('[data-el-section="search"]')
                }, {
                    name: "language search",
                    nodes: document.querySelectorAll('[data-el-section="language search"]')
                }, {
                    name: "secondary links",
                    nodes: document.querySelectorAll('[data-el-section="secondary links"]')
                }, {
                    name: "other languages",
                    nodes: document.querySelectorAll('[data-el-section="other languages"]')
                }, {
                    name: "other projects",
                    nodes: document.querySelectorAll('[data-el-section="other projects"]')
                }], document.addEventListener("click", function(e) {
                    var t, n = e || window.event,
                        a = n.target || n.srcElement;
                    a.matches("a, a *") && (t = function e(t) {
                        return "A" !== t.tagName && t.parentElement ? e(t.parentElement) : t
                    }(a), "search" === (s = {
                        event_type: "clickthrough",
                        destination: t.href,
                        section_used: u(t)
                    }).section_used && (s.selected_language = document.getElementById("searchLanguage").options[document.getElementById("searchLanguage").selectedIndex].lang), s.section_used && r.logEvent(o, s))
                }), document.addEventListener("change", function(e) {
                    var t = e || window.event,
                        n = t.target || t.srcElement;
                    if ("searchLanguage" === n.id) {
                        if (-1 === n.selectedIndex) return;
                        (s = {
                            event_type: "select-language",
                            selected_language: n.options[n.selectedIndex].lang
                        }).selected_language && r.logEvent(o, s)
                    }
                }), t = document.getElementsByTagName("form"), a = 0; a < t.length; a++) t[a].addEventListener("submit", g);
            l && (n = l.toString().split("=")[1], o.defaults.country = "US" === n && c ? c.toString().split("=")[1] : n, window.addEventListener("load", d)), window.addEventListener("load", d)
        }

        function u(e) {
            for (var t, n, a = {}, r = 0; r < i.length; r++)
                for (n = i[r].nodes, t = 0; t < n.length; t++) n[t].contains(e) && (a = i[r]);
            return a.name
        }

        function d() {
            s = {
                event_type: "landing"
            }, r.logEvent(o, s), s = null
        }

        function g(e) {
            var t = e || window.event,
                n = t.target || t.srcElement;
            null === s && (s = {
                event_type: "clickthrough",
                section_used: u(n),
                destination: n.action
            }), "search" === s.section_used && (s.selected_language = document.getElementById("searchLanguage").options[document.getElementById("searchLanguage").selectedIndex].lang), s.section_used && r.logEvent(o, s)
        }
    }(eventLoggingLite, wmTest), window.WMTypeAhead = function(e, t) {
        var E, x, c, i, u, n = "typeahead-suggestions",
            d = document.getElementById(n),
            a = document.getElementById(e),
            g = document.getElementById(t),
            s = Math.round(80 * getDevicePixelRatio());

        function l() {
            setTimeout(function() {
                var e = document.getElementById("api_opensearch");
                d.innerHTML = "", e && (e.src = !1), u.clear()
            }, 300)
        }

        function m(e) {
            for (var t, n, a, r, o, i, s, l, c, u, d, g, m, h, p, f = '<div class="suggestions-dropdown">', v = !1, w = "", y = "", b = 0; b < e.length; b++) e[b] && (y = (o = e[b]).description || "", v = !1, o.thumbnail && o.thumbnail.source && (v = (v = o.thumbnail.source.replace(/"/g, "%22")).replace(/'/g, "%27")), w = "", y && (w = "object" == typeof y && y[0] ? y[0].toString() : y.toString()), r = mw.html.element("p", {
                class: "suggestion-description"
            }, w), a = mw.html.element("h3", {
                class: "suggestion-title"
            }, new mw.html.Raw((i = o.title, s = x, p = h = m = g = d = u = c = l = void 0, g = mw.html.escape(mw.RegExp.escape(s)), m = new RegExp(g, "i"), h = i.search(m), p = mw.html.escape(i), 0 <= h && (l = h + g.length, c = i.substring(h, l), u = i.substring(0, h), d = i.substring(l, i.length), p = u + mw.html.element("em", {
                class: "suggestion-highlight"
            }, c) + d), p))), n = mw.html.element("div", {
                class: "suggestion-text"
            }, new mw.html.Raw(a + r)), t = mw.html.element("div", {
                class: "suggestion-thumbnail",
                style: !!v && "background-image:url(" + v + ")"
            }, ""), f += mw.html.element("a", {
                class: "suggestion-link",
                href: "https://" + E + "." + portalSearchDomain + "/wiki/" + encodeURIComponent(o.title.replace(/ /gi, "_"))
            }, new mw.html.Raw(n + t)));
            return f += "</div>"
        }

        function h(e, t) {
            for (var n, a = " active", r = 0; r < t.length; r++)(n = t[r]) !== e ? n.className = n.className.replace(a, "") : / active/.test(e.className) ? e.className = e.className.replace(a, "") : (e.className += a, u.setIndex(r))
        }
        return d || ((d = document.createElement("div")).id = n, a.appendChild(d)), window.callbackStack = {
            queue: {},
            index: -1,
            incrementIndex: function() {
                return this.index += 1, this.index
            },
            addCallback: function(e) {
                var t = this.incrementIndex();
                return this.queue[t] = e(t), t
            },
            deleteSelfFromQueue: function(e) {
                delete this.queue[e]
            },
            deletePrevCallbacks: function(e) {
                for (var t in this.deleteSelfFromQueue(e), this.queue) t < e && (this.queue[t] = this.deleteSelfFromQueue.bind(window.callbackStack, t))
            }
        }, u = {
            index: -1,
            max: 6,
            setMax: function(e) {
                this.max = e
            },
            increment: function(e) {
                return this.index += e, this.index < 0 && this.setIndex(this.max - 1), this.index === this.max && this.setIndex(0), this.index
            },
            setIndex: function(e) {
                return e <= this.max - 1 && (this.index = e), this.index
            },
            clear: function() {
                this.setIndex(-1)
            }
        }, window.portalOpensearchCallback = function(t) {
            var n, a, r, o, i, s = t,
                l = [];
            return function(e) {
                if (window.callbackStack.deletePrevCallbacks(s), document.activeElement === g) {
                    for (a in n = e.query && e.query.pages ? e.query.pages : []) r = n[a], l[r.index - 1] = r;
                    for (o = m(l), u.setMax(l.length), u.clear(), d.innerHTML = o, c = d.childNodes[0].childNodes, t = 0; t < c.length; t++)(i = c[t]).addEventListener("mouseenter", h.bind(this, i, c)), i.addEventListener("mouseleave", h.bind(this, i, c))
                }
            }
        }, g.addEventListener("keydown", function(e) {
            var t, n, a, r = e || window.event,
                o = r.which || r.keyCode;
            d.firstChild && (40 !== o && 38 !== o || (n = (t = d.firstChild.childNodes)[a = 40 === o ? u.increment(1) : u.increment(-1)].firstChild.childNodes[0], g.value = n.textContent, h(i = !!t && t[a], t)), 13 === o && i && (r.preventDefault ? r.preventDefault() : r.returnValue = !1, i.children[0].click()))
        }), window.addEventListener("click", function(e) {
            e.target.closest("#search-form") || l()
        }), {
            typeAheadEl: d,
            query: function(e, t) {
                var n, a, r, o = document.getElementById("api_opensearch"),
                    i = document.getElementsByTagName("head")[0];
                E = encodeURIComponent(t) || "en", 0 !== (x = encodeURIComponent(e)).length ? (n = "//" + E + "." + portalSearchDomain + "/w/api.php?", o && i.removeChild(o), (o = document.createElement("script")).id = "api_opensearch", a = window.callbackStack.addCallback(window.portalOpensearchCallback), r = {
                    action: "query",
                    format: "json",
                    generator: "prefixsearch",
                    prop: "pageprops|pageimages|description",
                    redirects: "",
                    ppprop: "displaytitle",
                    piprop: "thumbnail",
                    pithumbsize: s,
                    pilimit: 6,
                    gpssearch: e,
                    gpsnamespace: 0,
                    gpslimit: 6,
                    callback: "callbackStack.queue[" + a + "]"
                }, o.src = n + function(e) {
                    var t, n = [];
                    for (t in e) e.hasOwnProperty(t) && n.push(t + "=" + encodeURIComponent(e[t]));
                    return n.join("&")
                }(r), i.appendChild(o)) : l()
            }
        }
    },
    function(e) {
        var t = document.getElementById("searchInput"),
            n = new e("search-input", "searchInput"),
            a = "oninput" in document ? "input" : "propertychange";
        t.addEventListener("focus", _.debounce(function() {
            n.query(t.value, document.getElementById("searchLanguage").value)
        }, 100)), t.addEventListener(a, _.debounce(function() {
            n.query(t.value, document.getElementById("searchLanguage").value)
        }, 100))
    }((wmTest, WMTypeAhead)),
    function(i) {
        var o, s, a = wmTest.userLangs,
            l = document.querySelectorAll(".central-featured-lang"),
            r = document.querySelector(".central-featured"),
            e = i.storage.get("translationHash");

        function c(e) {
            var t;
            try {
                t = JSON.parse(e)
            } catch (e) {
                t = ""
            }
            return t
        }

        function u(e, t) {
            var n = e.getElementsByTagName("a")[0],
                a = t.name.replace(/<\/?[^>]+(>|$)/g, "");
            n.setAttribute("href", "//" + t.url), n.setAttribute("id", "js-link-box-" + t.lang), n.setAttribute("data-slogan", t.slogan || "The Free Encyclopedia"), n.setAttribute("title", a + " — " + t.siteName + " — " + (t.slogan || "")), e.setAttribute("lang", t.lang), e.getElementsByTagName("strong")[0].textContent = a, e.getElementsByTagName("bdi")[0].textContent = t.numPages + "+", e.getElementsByTagName("span")[0].textContent = t.entries || ""
        }

        function d() {
            var e, t, n, a, r = !0;
            for (l = document.querySelectorAll(".central-featured-lang"), a = 0; a < l.length && !0 === r; a++) t = l[a].getAttribute("lang"), r = 0 <= o.indexOf(t);
            for (a = 0; a < l.length; a++) r && (e = l[a]).className !== (n = "central-featured-lang lang" + (a + 1)) && (e.className = n)
        }

        function g(e, t) {
            var n, a, r, o;
            s[t] ? u(e, s[t]) : (n = e, a = t, (o = new XMLHttpRequest).open("GET", encodeURI("portal/wikipedia.org/assets/l10n/" + a + "-" + translationsHash + ".json"), !0), o.onload = function() {
                200 === o.status && (r = c(this.responseText)) && (u(n, r), d(), (s = c(i.storage.get("storedTranslations")) || {})[a] = r, i.storage.set("storedTranslations", JSON.stringify(s)))
            }, o.send())
        }
        s = c(i.storage.get("storedTranslations")) || {}, o = Array.prototype.map.call(l, function(e) {
            return e.getAttribute("lang")
        }), e !== translationsHash && (i.storage.set("translationHash", translationsHash), i.storage.remove("storedTranslations")), wmL10nVisible.ready || (function() {
            for (var e, t, n = 0; n < a.length; n++) e = a[n], 0 <= (t = o.indexOf(e)) ? t === n || o.splice(n, 0, o.splice(t, 1)[0]) : (o.splice(n, 0, e), o.pop())
        }(), function() {
            for (var e, t, n, a = 0; a < o.length; a++) l = document.querySelectorAll(".central-featured-lang"), e = o[a], (t = document.querySelector(".central-featured-lang[lang=" + e + "]")) ? Array.prototype.indexOf.call(l, t) !== a && r.insertBefore(t, l[a]) : (g(n = function() {
                for (var e, t = null, n = o.length - 1; 0 <= n && null === t; n--) e = l[n].getAttribute("lang"), o.indexOf(e) < 0 && (t = l[n]);
                return t
            }(), e), r.insertBefore(n, l[a])), (t || n).setAttribute("dir", 0 <= rtlLangs.indexOf(e) ? "rtl" : "ltr")
        }(), d())
    }(mw),
    function() {
        "use strict";

        function f(e) {
            return document.getElementById(e)
        }

        function v(e) {
            var t, n;
            document.querySelector && "www-wiktionary-org" === document.body.id && !e.match(/\W/) && (n = (t = document.querySelector('option[lang|="' + e + '"]')) && t.getAttribute("data-logo")) && document.body.setAttribute("data-logo", n)
        }

        function w() {
            return (navigator.languages && navigator.languages[0] || navigator.language || navigator.userLanguage || "").toLowerCase().split("-")[0]
        }
        doWhenReady(function() {
            var e, t, n, a, r, o, i, s, l, c, u, d, g, m, h, p = ((c = document.cookie.match(/(?:^|\W)searchLang=([^;]+)/)) ? c[1] : w()).toLowerCase();
            if (p && (e = getIso639(p), t = f("searchLanguage"))) {
                for (a = 0, r = (n = t.getElementsByTagName("option")).length; !o && a < r; a += 1) n[a].value === e && (o = e);
                !o && document.querySelector && (i = document.querySelector('.langlist a[lang|="' + e + '"]')) && (o = e, (s = document.createElement("option")).setAttribute("lang", e), s.setAttribute("value", e), l = i.textContent || i.innerText || e, s.textContent = l, t.appendChild(s)), o && (v(t.value = o), u = o, d = document.createElement("link"), g = window.location.hostname.split("."), m = g.pop(), h = g.pop(), d.rel = "preconnect", d.href = "//" + u + "." + h + "." + m, document.head.appendChild(d))
            }
        }), doWhenReady(function() {
            var e, t, n, a = f("searchInput"),
                r = f("searchLanguage");
            if (a)
                for (void 0 === a.autofocus ? a.focus() : window.scroll(0, 0), e = location.search && location.search.substr(1).split("&"), t = 0; t < e.length; t += 1)
                    if ("search" === (n = e[t].split("="))[0] && n[1]) {
                        a.value = decodeURIComponent(n[1].replace(/\+/g, " "));
                        break
                    } r.addEventListener("change", function() {
                var e, t, n;
                r.blur(), (e = r.value) && (t = w().match(/^\w+/), n = new Date, v(e), t && t[0] === e ? n.setTime(n.getTime() - 1) : n.setFullYear(n.getFullYear() + 1), document.cookie = "searchLang=" + e + ";expires=" + n.toUTCString() + ";domain=" + location.host + ";")
            })
        }), doWhenReady(function() {
            var e = document.searchwiki && document.searchwiki.elements.uselang;
            e && (e.value = w())
        }), doWhenReady(function() {
            var e, t, n, a, r, o = getDevicePixelRatio(),
                i = new Image;
            if (1 < o && void 0 === i.srcset)
                for (e = document.getElementsByTagName("img"), r = 0; r < e.length; r++) "string" == typeof(n = (t = e[r]).getAttribute("srcset")) && "" !== n && void 0 !== (a = function(e, t) {
                    for (var n, a, r = {
                            ratio: 1
                        }, o = t.split(/ *, */), i = 0; i < o.length; i++)(a = (n = o[i].match(/\s*(\S+)(?:\s*([\d.]+)w)?(?:\s*([\d.]+)h)?(?:\s*([\d.]+)x)?\s*/))[4] && parseFloat(n[4])) <= e && a > r.ratio && (r.ratio = a, r.src = n[1], r.width = n[2] && parseFloat(n[2]), r.height = n[3] && parseFloat(n[3]));
                    return r
                }(o, n)).src && (t.setAttribute("src", a.src), void 0 !== a.width && t.setAttribute("width", a.width), void 0 !== a.height && t.setAttribute("height", a.height))
        })
    }(), window.mw || (window.mw = window.mediaWiki = {
        loader: {
            state: function() {}
        }
    }),
    function() {
        var e = document.getElementById("js-lang-list-button");

        function t() {
            / lang-list-active /g.test(document.body.className) ? (document.body.className = document.body.className.replace(" lang-list-active ", ""), mw.storage.set("lang-list-active", "false")) : (document.body.className += " lang-list-active ", mw.storage.set("lang-list-active", "true"))
        }
        "true" !== mw.storage.get("lang-list-active") && ! function(e) {
            for (var t, n = document.getElementsByTagName("a"), a = !0, r = 0; r < n.length && a; r++)(t = n[r].getAttribute("lang")) && 0 <= e.indexOf(t) && (a = !1);
            return a
        }(wmTest.userLangs) || t(), e.addEventListener("click", function() {
            t()
        })
    }(),
    function(e, t, a, n) {
        var r, o, i, s, l, c = e.userLangs[0];

        function u(e) {
            var t;
            try {
                t = JSON.parse(e)
            } catch (e) {
                t = ""
            }
            return t
        }

        function d(e) {
            if (-1 !== ["zh", "zh-hans", "zh-cn", "zh-sg", "zh-my", "zh-hans-cn", "zh-hans-sg", "zh-hans-my"].indexOf(e)) return !0;
            if (["zh-hk", "zh-tw", "zh-mo", "zh-hant-hk", "zh-hant-tw", "zh-hant-mo"].indexOf(-1 !== e)) return !1;
            throw new TypeError(e + " is not a Chinese locale!")
        }
        if ("en" !== c)
            if ("zh" === c && (r = (navigator.languages && navigator.languages[0] || navigator.language || navigator.userLanguage || "").toLowerCase(), function(e) {
                    var t, n, a, r, o = "data-hans",
                        i = "data-hant",
                        s = "data-title-hans",
                        l = "data-title-hant";
                    try {
                        r = d(e)
                    } catch (e) {
                        return
                    }
                    for (n = document.querySelectorAll(".jscnconv, #js-link-box-zh"), t = 0; t < n.length; t++) a = n[t], r ? (a.hasAttribute(o) && (a.textContent = a.getAttribute(o)), a.hasAttribute(s) && (a.title = a.getAttribute(s))) : (a.hasAttribute(i) && (a.textContent = a.getAttribute(i)), a.hasAttribute(l) && (a.title = a.getAttribute(l)))
                }(c = d(r) ? "zh-hans" : "zh-hant")), l = a.storage.get("translationHash"), (o = t === l && l && u(a.storage.get("storedTranslations")) || {})[c]) {
                if (s = o[c], wmL10nVisible.ready) return;
                h(c), m(s)
            } else(i = new XMLHttpRequest).open("GET", encodeURI("portal/" + portalSearchDomain + "/assets/l10n/" + c + "-" + t + ".json"), !0), i.onreadystatechange = function() {
                if (4 === i.readyState) {
                    if (200 !== i.status) return void wmL10nVisible.makeVisible();
                    if (s = u(this.responseText)) {
                        if (e = c, t = s, (n = u(a.storage.get("storedTranslations")) || {})[e] = t, a.storage.set("storedTranslations", JSON.stringify(n)), wmL10nVisible.ready) return;
                        h(c), m(s)
                    }
                }
                var e, t, n
            }, i.send();
        else wmL10nVisible.makeVisible();

        function g(e, t) {
            var n = 0;
            for (t = String(t).split("."); n < t.length;) {
                if (null == e) return;
                e = e[t[n++]]
            }
            return e
        }

        function m(e) {
            for (var t, n, a, r, o, i = document.querySelectorAll(".jsl10n"), s = new RegExp(/<a[^>]*>([^<]+)<\/a>/), l = 0; l < i.length; l++)
                if ("string" == typeof(a = g(e, n = (t = i[l]).getAttribute("data-jsl10n").replace("portal.", translationsPortalKey + "."))) && 0 < a.length) switch (n) {
                    case "app-links.other":
                        s.test(a) ? t.innerHTML = a : t.firstChild.textContent = a;
                        break;
                    case "license":
                        t.innerHTML = a;
                        break;
                    case "terms":
                        t.firstChild.textContent = a, (r = g(e, "terms-link")) && t.firstChild.setAttribute("href", r);
                        break;
                    case "privacy-policy":
                        t.firstChild.textContent = a, (o = g(e, "privacy-policy-link")) && t.firstChild.setAttribute("href", o);
                        break;
                    default:
                        t.textContent = a, t.setAttribute("lang", e.lang)
                }
            wmL10nVisible.makeVisible()
        }

        function h(e) {
            document.documentElement.lang = e, 0 <= n.indexOf(e) ? document.dir = "rtl" : document.dir = "ltr"
        }
    }(wmTest, translationsHash, mw, rtlLangs);