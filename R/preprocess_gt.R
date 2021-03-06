maybe_longlat <- function (bb) (bb[1] >= -180.1 && bb[3] <= 180.1 && bb[2] >= -90.1 && bb[4] <= 90.1)

preprocess_gt <- function(x, interactive, orig_crs) {
	set.bounds <- bg.color <- set.zoom.limits <- legend.position <- colorNA <- NULL
	
	
	gt <- get(".tmapOptions", envir = .TMAP_CACHE)
	
	gts <- x[names(x) == "tm_layout"]
	if (length(gts)) {
		for (i in 1L:length(gts)) {
			g <- gts[[i]]
			if (!is.na(g$style)) {
				if (i !=1) warning("Note that tm_style(\"", g$style, "\") resets all options set with tm_layout, tm_view, tm_format, or tm_legend. It is therefore recommended to place the tm_style element prior to the other tm_layout/tm_view/tm_format/tm_legend elements.", call. = FALSE)
				gt <- .defaultTmapOptions
				if (g$style != "white") {
					styleOptions <- get(".tmapStyles", envir = .TMAP_CACHE)[[g$style]]
					gt[names(styleOptions)] <- styleOptions
				}
			} 
			g$style <- NULL
			if (length(g)) gt[names(g)] <- g
		}
	}

	# gt <- do.call(tln, args = list())$tm_layout
	# gts <- x[names(x)=="tm_layout"]
	# if (length(gts)) {
	# 	gtsn <- length(gts)
	# 	extraCall <- character(0)
	# 	for (i in 1:gtsn) {
	# 		gt[gts[[i]]$call] <- gts[[i]][gts[[i]]$call]
	# 		if ("attr.color" %in% gts[[i]]$call) gt[c("earth.boundary.color", "legend.text.color", "title.color")] <- gts[[i]]["attr.color"]
	# 		extraCall <- c(extraCall, gts[[i]]$call)
	# 	}
	# 	gt$call <- c(gt$call, extraCall)
	# }

	# # process tm_view: merge multiple to one gv
	# if (any("tm_view" %in% names(x))) {
	# 	vs <- which("tm_view" == names(x))
	# 	gv <- x[[vs[1]]]
	# 	if (length(vs)>1) {
	# 		for (i in 2:length(vs)) {
	# 			gv2 <- x[[vs[i]]]
	# 			gv[gv2$call] <- gv2[gv2$call]
	# 			gv$call <- unique(c(gv$call, gv2$call))
	# 		}
	# 	}
	# } else {
	# 	gv <- tm_view()$tm_view
	# }
	
	## preprocess gt
	gt <- within(gt, {
		pc <- list(sepia.intensity=sepia.intensity, saturation=saturation)
		sepia.intensity <- NULL
		saturation <- NULL
		
		if (!"scientific" %in% names(legend.format)) legend.format$scientific <- FALSE
		if (!"digits" %in% names(legend.format)) legend.format$digits <- NA
		if (!"text.separator" %in% names(legend.format)) legend.format$text.separator <- "to"
		if (!"text.less.than" %in% names(legend.format)) legend.format$text.less.than <- c("Less", "than")
		if (!"text.or.more" %in% names(legend.format)) legend.format$text.or.more <- c("or", "more")
		if (!"text.align" %in% names(legend.format)) legend.format$text.align <- NA
		if (!"text.to.columns" %in% names(legend.format)) legend.format$text.to.columns <- FALSE
		
		# put aes colors in right order and name them
		if (length(aes.color)==1 && is.null(names(aes.color))) names(aes.color) <- "base"
		
		if (!is.null(names(aes.color))) {
			aes.colors <- c(fill="grey85", borders="grey40", symbols="blueviolet", dots="black", lines="red", text="black", na="grey60")
			aes.colors[names(aes.color)] <- aes.color
		} else {
			aes.colors <- rep(aes.color, length.out=7)
			names(aes.colors) <- c("fill", "borders", "symbols", "dots", "lines", "text", "na")
		}
		aes.colors <- vapply(aes.colors, function(ac) if (is.na(ac)) "#000000" else ac, character(1))
		
		# override na
		if (interactive) aes.colors["na"] <- if (is.null(colorNA)) "#00000000" else if (is.na(colorNA)) aes.colors["na"] else colorNA
		
		aes.colors.light <- vapply(aes.colors, is_light, logical(1))
		aes.color <- NULL
		
		######################### tm_view
		
		if (!get(".internet", envir = .TMAP_CACHE) || identical(basemaps, FALSE)) {
			basemaps <- character(0)
		} else {
			# with basemap tiles
			#if (is.na(basemaps.alpha)) basemaps.alpha <- gt$basemaps.alpha
			#if (identical(basemaps, NA)) basemaps <- gt$basemaps
			if (identical(basemaps, TRUE)) basemaps <- c("OpenStreetMap", "OpenStreetMap.Mapnik", "OpenTopoMap", "Stamen.Watercolor", "Esri.WorldTopoMap", "Esri.WorldImagery", "CartoDB.Positron", "CartoDB.DarkMatter")
			basemaps.alpha <- rep(basemaps.alpha, length.out=length(basemaps))
			if (is.na(alpha)) alpha <- .7
		}
		if (!is.logical(set.bounds)) if (!length(set.bounds)==4 || !is.numeric(set.bounds)) stop("Incorrect set_bounds argument", call.=FALSE)
		
		if (!is.null(bbox)) {
			if (is.character(bbox)) {
				res <- geocode_OSM(bbox)
				bbox <- res$bbox
				center <- res$coords
				res <- NULL
			} else {
				bbox <- bb(bbox)
				if (is.na(attr(bbox, "crs"))) {
					if (!maybe_longlat(bbox)) stop("bounding box specified with tm_view (or tmap_options) is projected, but the projection is unknown", call. = FALSE)
				} else {
					bbox <- bb(bbox, projection = .crs_longlat)
				}
				center <- NULL
			}
			set.view <- NA
		}

		if (!is.na(set.view[1])) {
			if (!is.numeric(set.view)) stop("set.view is not numeric")
			if (!length(set.view) %in% c(1,3)) stop("set.view does not have length 3")
		}
		if (!is.na(set.zoom.limits[1])) {
			if (!is.numeric(set.zoom.limits)) stop("set.zoom.limits is not numeric")
			if (!length(set.zoom.limits)==2) stop("set.zoom.limits does not have length 2")
			if (set.zoom.limits[1]<0 || set.zoom.limits[1] >= set.zoom.limits[2]) stop("incorrect set.zoom.limits")
		}
		if (!is.na(set.view[1]) && !is.na(set.zoom.limits[1])) {
			if (set.view[3] < set.zoom.limits[1]) {
				warning("default zoom smaller than minimum zoom, now it is set to the minimum zoom")
				set.view[3] <- set.zoom.limits[1]
			}
			if (set.view[3] > set.zoom.limits[2]) {
				warning("default zoom larger than maximum zoom, now it is set to the maximum zoom")
				set.view[3] <- set.zoom.limits[2]
			}
		}
		view.legend.position <- if (is.na(view.legend.position)[1]) {
			if (is.null(legend.position)) {
				"topright"
			} else if (is.character(legend.position) && 
					   tolower(legend.position[1]) %in% c("left", "right") &&
					   tolower(legend.position[2]) %in% c("top", "bottom")) {
				paste(tolower(legend.position[c(2,1)]), collapse="")
			}
		} else if (is.character(view.legend.position) && 
				   view.legend.position[1] %in% c("left", "right") &&
				   view.legend.position[2] %in% c("top", "bottom")) {
			paste(view.legend.position[c(2,1)], collapse="")
		} else {
			"topright"
		}
		
		if (!inherits(projection, "leaflet_crs")) {
			
			if (projection==0) {
				epsg <- get_epsg_number(orig_crs)
				if (is.na(epsg)) {
					projection <- 3857
				} else {
					projection <- epsg
				}
			}
			
			if (projection %in% c(3857, 4326, 3395)) {
				projection <- leaflet::leafletCRS(crsClass = paste("L.CRS.EPSG", projection, sep=""))	
			} else {
				projection <- leaflet::leafletCRS(crsClass = "L.Proj.CRS", 
												  code= paste("EPSG", projection, sep=":"),
												  proj4def=get_proj4(projection),
												  resolutions = c(65536, 32768, 16384, 8192, 4096, 2048,1024, 512, 256, 128))	
			}
			
			
		}

				
	})
	

	# append view to layout
	# gt[c("basemaps", "basemaps.alpha")] <- NULL
	# gv[c("colorNA", "call", "legend.position")] <- NULL
	# gt <- c(gt, gv)
	
	gtnull <- names(which(vapply(gt, is.null, logical(1))))
	gt[gtnull] <- list(NULL)
	gt
}
