

check_fill_specials <- function(x, g, gt, shpcols, data, nx) {
	if (attr(data, "kernel_density") && !("col" %in% g$call) && "level" %in% shpcols) {
		is.colors <- FALSE
		x <- "level"
	} else if (!all(x %in% shpcols)) {
		# check for direct color input
		is.colors <- all(valid_colors(x))
		if (is.colors) {
			x <- do.call("process_color", c(list(col=col2hex(x), alpha=g$alpha), gt$pc))
			for (i in 1:nx) data[[paste("COLOR", i, sep="_")]] <- x[i]
			x <- paste("COLOR", 1:nx, sep="_")
		} else if (x[1]=="MAP_COLORS") {
			palette <- if (is.null(g$palette)) {
				gt$aes.palette[["cat"]]
			} else if (g$palette[1] %in% c("seq", "div", "cat")) {
				gt$aes.palette[[g$palette[1]]] 
			} else g$palette
			mapcols <- do.call("map_coloring", args = c(list(x=attr(data, "NB"), palette=palette, contrast = g$contrast), g$map_coloring))
			mapcols <- do.call("process_color", c(list(col=mapcols, alpha=g$alpha), gt$pc))
			
			for (i in 1:nx) data[[paste("COLOR", i, sep="_")]] <- mapcols
			x <- paste("COLOR", 1:nx, sep="_")
		} else {
			stop("Fill argument neither colors nor valid variable name(s)", call. = FALSE)
		}
	} else {
		is.colors <- FALSE
	}
	
	list(x = x,
		 data = data,
		 is.colors = is.colors)
}


check_poly_sizes <- function(g, data, nx, islist) {
	# process areas
	if (is.null(g$area)) {
		area_var <- "SHAPE_AREAS"
	} else {
		area_var <- g$area
	}
	
	areas <- data[[area_var]]
	
	if (any(is.na(areas)) || any(is.infinite(areas))) {
		if (g$convert2density) {
			warning("Some polygon areas cannot be determined. Therefore, convert2density is set to FALSE.", call. = FALSE)
		}
		areas_na_inf <- is.na(areas) | is.infinite(areas)
		areas[areas_na_inf] <- mean(areas[!areas_na_inf])
		
	}
	areas_prop <- as.numeric(areas/sum(areas, na.rm=TRUE))
	
	tiny <- areas_prop < g$thres.poly
	if (all(tiny)) warning("all relative area sizes are below thres.poly", call. = FALSE)
	
	sel <- !tiny #if (islist) rep(list(!tiny), nx) else !tiny
	list(areas = areas, sel = sel)
}


process_fill <- function(data, g, gt, gby, z, interactive) {
	
	## aesthetics
	xs <- list(fill = g$col)
	process_aes(type = "fill", xs, "xfill", "fill", data, g, gt, gby, z, interactive)
}

