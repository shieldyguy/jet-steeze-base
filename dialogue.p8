pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
D_DEF_ADV_BTN_ID = 5

function d_init(cabi)
    d_adv_btn_id = cabi or D_DEF_ADV_BTN_ID
    d_s_txt_c = 7
    d_s_tlh_px = 6
    d_s_sfx_tw0 = 0
    d_s_sfx_tw1 = 1
    d_s_sfx_tw2 = 2
    d_s_sfx_tw_skp = 4
    d_s_sfx_tw_skp_cnt = 0
    d_s_sfx_nl = 0
    d_s_sfx_nm = 0
    d_s_ptd_fr = 6
    d_s_bpp_x = 4
    d_s_bbs = 6
    d_s_boc = 7
    d_s_bfc = 1
    d_s_bxo_char = 15
    d_s_crn_spr_id = 10
    d_s_arw_spr_id = 12
    d_s_flp_thr_sx = 75
    d_s_cb_min_w_t = 2
    d_s_cb_max_w_t = 8
    d_s_cb_ml = 4
    d_s_cb_lwc = 10
    d_s_cb_hwl = 8
    d_s_nb_min_w_t = 2
    d_s_nb_max_w_t = 13
    d_s_nb_ml = 4
    d_s_nb_lwc = 18
    d_s_nb_hwl = 16
    d_pl = {}
    d_rst_dsp_stt()
end

function d_rst_dsp_stt()
    d_dlc = {}
    local mpl = max(d_s_cb_ml, d_s_nb_ml)
    for i = 1, mpl do
        add(d_dlc, "")
    end
    d_cli = 0
    d_tt = 0
end

function d_drw_bbl(x, y, wt, ht, flpd, nrtn)
    local bs = d_s_bbs
    local oc = d_s_boc
    local fc = d_s_bfc
    local xov = d_s_bxo_char
    local cspr = d_s_crn_spr_id
    local aspr = d_s_arw_spr_id
    flpd = flpd or false
    pal(1, d_s_bfc)
    pal(7, d_s_boc)
    if nrtn then
        x += peek2(0x5f28)
        y += peek2(0x5f2a)
    else
        y -= 8
        if flpd then
            x -= xov
        else
            x += xov
        end
    end
    ht += 1
    local lx, rx
    if flpd then
        rx = x
        lx = x - (wt - 1) * bs
    else
        lx = x
        rx = x + (wt - 1) * bs
    end
    local ty = y - (ht - 1) * bs
    for i = 1, wt - 2 do
        local seg_x = lx + i * bs
        rectfill(seg_x, ty, seg_x + bs, ty + bs, fc)
        line(seg_x, ty, seg_x + bs, ty, oc)
        rectfill(seg_x, y, seg_x + bs, y + bs, fc)
        line(seg_x, y + bs, seg_x + bs, y + bs, oc)
    end
    for j = 1, ht - 2 do
        local edge_y = ty + j * bs
        rectfill(lx, edge_y, lx + bs, edge_y + bs, fc)
        line(lx, edge_y, lx, edge_y + bs, oc)
        rectfill(rx, edge_y, rx + bs - 1, edge_y + bs, fc)
        line(rx + bs - 1, edge_y, rx + bs - 1, edge_y + bs, oc)
    end
    rectfill(
        lx + bs, ty + bs,
        lx + bs * (wt - 1), ty + bs * (ht - 1), fc
    )
    spr(cspr, lx, ty, 1, 1, false, false)
    spr(cspr, rx - 2, ty, 1, 1, true, false)
    if not nrtn then
        if not flpd then
            rectfill(lx, y, lx + bs - 1, y + bs - 1, fc)
            line(lx, y + bs, lx + bs - 1, y + bs, oc)
            spr(cspr, rx - 2, y - 1, 1, 1, true, true)
        else
            rectfill(rx, y, rx + bs - 1, y + bs - 1, fc)
            line(rx, y + bs, rx + bs - 1, y + bs, oc)
            spr(cspr, lx, y - 1, 1, 1, false, true)
        end
        if flpd then
            spr(aspr, x + bs - 1, y, 1, 1, true, false)
            pset(x + bs - 1, y, oc)
        else
            spr(aspr, x - bs, y, 1, 1, false, false)
            pset(x, y, oc)
        end
    else
        spr(cspr, rx - 2, y - 1, 1, 1, true, true)
        spr(cspr, lx, y - 1, 1, 1, false, true)
    end
    pal()
    return ty + 4, lx + 4
end

function d_show(txt, spkr, cb, vc)
    local lns = {}
    local cl = ""
    local cw = ""
    local is_nrtn = false
    if spkr and spkr.name == "narrator" then
        is_nrtn = true
    end
    local wc = is_nrtn and d_s_nb_lwc or d_s_cb_lwc
    local hl = is_nrtn and d_s_nb_hwl or d_s_cb_hwl
    for i = 1, #txt do
        local char = sub(txt, i, i)
        cw = cw .. char
        if char == " " or #cw > hl then
            if char ~= " " and #cw > hl then
                cw = cw .. "-"
            end
            if #cw + #cl > wc then
                add(lns, cl)
                cl = ""
            end
            cl = cl .. cw
            cw = ""
        end
    end
    if #cw > 0 then
        if #cw + #cl > wc then
            add(lns, cl)
            cl = cw
        else
            cl = cl .. cw
        end
    end
    if cl ~= "" then
        add(lns, cl)
    end
    local mlc = 0
    for _, line_text in pairs(lns) do
        mlc = max(mlc, #line_text)
    end
    local tpw = mlc * 4
    local tcpw = tpw + (d_s_bpp_x * 2)
    local rt = ceil(tcpw / d_s_bbs)
    local min_wt = is_nrtn and d_s_nb_min_w_t or d_s_cb_min_w_t
    local max_wt = is_nrtn and d_s_nb_max_w_t or d_s_cb_max_w_t
    local cwt = max(min_wt, min(max_wt, rt))
    local e = {
        text_lines = lns,
        speaker_entity = spkr,
        on_finish_callback = cb or 0,
        is_narration = is_nrtn,
        calculated_width_tiles = cwt,
        voice = vc or { 63, 63 }
    }
    add(d_pl, e)
end

function d_nxt_ln_msg()
    d_cli += 1
    for i = 1, #d_dlc - 1 do
        d_dlc[i] = d_dlc[i + 1]
    end
    local ce = d_pl[1]
    if ce and d_cli <= #ce.text_lines and #ce.text_lines[d_cli] > 0 then
        d_dlc[#d_dlc] = sub(ce.text_lines[d_cli], 1, 1)
        d_tt = 1
    else
        d_dlc[#d_dlc] = ""
    end
end

function d_nxt_msg_pl()
    local ce = d_pl[1]
    if ce and ce.on_finish_callback ~= 0 then
        ce.on_finish_callback()
    end
    if #d_pl > 0 then
        del(d_pl, d_pl[1])
    end
    d_rst_dsp_stt()
end

function d_upd()
    if #d_pl == 0 then return end
    local ce = d_pl[1]
    if d_cli == 0 then
        d_cli = 1
        if ce and #ce.text_lines > 0 and #ce.text_lines[1] > 0 then
            local flt = ce.text_lines[1]
            local fc = sub(flt, 1, 1)
            d_dlc[#d_dlc] = fc
            d_tt = 1
            if fc ~= " " then sfx(rnd({ ce.voice[1], ce.voice[2] })) end
            if fc == "." then d_tt = d_s_ptd_fr end
        elseif ce and #ce.text_lines > 0 then
            d_nxt_ln_msg()
        else
            d_dlc[#d_dlc] = ""
        end
    end
    if not ce or not ce.text_lines or d_cli == 0 or d_cli > #ce.text_lines then
        if btnp(d_adv_btn_id) then
            d_nxt_msg_pl()
        end
        return
    end
    local clli = #d_dlc
    local stxl = ce.text_lines
    local cdlt = d_dlc[clli]
    local cslt = stxl[d_cli]
    local cdll = #cdlt
    local is_clft = cdll >= #cslt
    local is_llm = d_cli >= #stxl
    if is_clft and is_llm then
        if btnp(d_adv_btn_id) then
            d_nxt_msg_pl()
            return
        end
    elseif d_cli > 0 and d_cli <= #stxl then
        d_tt -= 1
        if not is_clft then
            if d_tt <= 0 then
                local nci = cdll + 1
                local nc = sub(cslt, nci, nci)
                d_tt = 1
                if nc ~= " " then
                    d_s_sfx_tw_skp_cnt += 1
                    if d_s_sfx_tw_skp_cnt >= d_s_sfx_tw_skp then
                        d_s_sfx_tw_skp_cnt = 0
                        sfx(rnd({ ce.voice[1], ce.voice[2] }))
                    end
                end
                if nc == "." then
                    d_tt = d_s_ptd_fr
                end
                d_dlc[clli] = cdlt .. nc
            end
            if btnp(d_adv_btn_id) then
                d_dlc[clli] = cslt
                d_tt = 0
            end
        else
            d_nxt_ln_msg()
        end
    end
end

function d_draw()
    if #d_pl == 0 then return end
    if d_cli == 0 then
        return
    end
    local ce = d_pl[1]
    if not ce or not ce.speaker_entity then
        if not (ce and ce.is_narration) then
            return
        end
    end
    local spkr = ce.speaker_entity
    local is_nrtn_flg = ce.is_narration
    local byo = 0
    local cam_x = peek2(0x5f28)
    local cam_y = peek2(0x5f2a)
    local scr_x = spkr.x - cam_x
    local scr_y = spkr.y - cam_y
    local cmdl = is_nrtn_flg and d_s_nb_ml or d_s_cb_ml
    local bwt = ce.calculated_width_tiles
    local dcal = #d_dlc
    local ul = 0
    for i = 1, dcal do
        if d_dlc[i] != "" then
            ul += 1
        end
    end
    ul = min(ul, cmdl)
    local bht = ul or 1
    local lhp = d_s_tlh_px
    local no = 0
    if is_nrtn_flg then
        no = ul * lhp
    end
    local flpd = false
    local brx, bry
    if is_nrtn_flg then
        brx = spkr and spkr.x or 0
        bry = spkr and spkr.y or 0
    else
        brx = spkr.x
        bry = spkr.y
        if scr_x > d_s_flp_thr_sx then
            flpd = true
        end
        if scr_x < 0 then
            brx = cam_x
        elseif scr_x > 128 then
            brx = cam_x + 128
        end
        local byst = ul * lhp + 10
        if scr_y < byst then
            bry = cam_y + byst
        elseif scr_y > 125 then
            bry = cam_y + 125
        end
    end
    local fby = bry + no + byo
    local ty, tx = d_drw_bbl(brx, fby, bwt, bht, flpd, is_nrtn_flg)
    local lnum = 0
    for i = 1, dcal do
        if d_dlc[i] != "" and lnum < cmdl then
            lnum += 1
            print(d_dlc[i], tx, ty + ((lnum - 1) * lhp), d_s_txt_c)
        end
    end
end
