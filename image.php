<?php 
/*
 * ImageFile by Eric Winchell.
 * @author Eric Winchell
 * @version 0.1 
 * @license MIT
 */

class Image {
    var $width = null;
    var $height = null;

    /**
     * Open Image
     * @return int GD image resource
     */
	function open($file) {
		$this->im_info = getimagesize($file);
        # JPEG:
        $im = imagecreatefromjpeg($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # GIF:
        $im = imagecreatefromgif($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # PNG:
        $im = imagecreatefrompng($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # GD File:
        $im = imagecreatefromgd($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # GD2 File:
        $im = imagecreatefromgd2($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # WBMP:
        $im = imagecreatefromwbmp($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # XBM:
        $im = imagecreatefromxbm($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # XPM:
        $im = imagecreatefromxpm($file);
        if ($im !== false) { $this->setImage($im); $this->setSize(); return $im; }

        # Try and load from string:
        $im = imagecreatefromstring(file_get_contents($file));
        if ($im !== false) { $this->setSize(); return $im; }

        return false;
	}
	
	function setSize() {
		$this->width = imagesx($this->im);
		$this->height = imagesy($this->im);
	}

	function setImage(&$im) { $this->im =& $im; }
	
	function resize($new_width, $new_height) {
		$resized_im = imagecreatetruecolor($new_width, $new_height);
		$resized_im = $this->handle_transparency($resized_im);
		imagecopyresampled($resized_im, $this->im, 0, 0, 0, 0, $new_width, $new_height, $this->width, $this->height);
		$this->resized_im = $resized_im;
	}
	
	function resize_max($max_height, $max_width) {
		// Only resize if necessary.
		if(!($max_height > $this->height && $max_width > $this->width)) {
			// If the width is greater than the height, then calculate based on the width.
			if($this->width > $max_width) {
				// Set a new width, and calculate new height
				$potential_height = $this->height * ($max_width/$this->width);
				if($potential_height > $max_height) {
					$final_width = $max_width * ($max_height/$potential_height);
					$final_height = $max_height;
				} else {
					$final_width = $max_width;
					$final_height = $potential_height;				
				}
			} else { // this->height > $max_height
				// Or set a new height, and calculate new width
				$potential_width = $this->width * ($max_height/$this->height);
				if($potential_width > $max_width) {
					$final_height = $max_height * ($max_width/$potential_width);
					$final_width = $max_width;
				} else {
					$final_height = $max_height;
					$final_width = $potential_width;				
				}
			}

            $resized_im = imagecreatetruecolor($final_width, $final_height);
            $resized_im = $this->handle_transparency($resized_im);
            imagecopyresampled($resized_im, $this->im, 0, 0, 0, 0, $final_width, $final_height, $this->width, $this->height);
            $this->resized_im = $resized_im;

		// No resizing necessary, so just handle the transparency.
		} else {
			$this->resized_im = $this->handle_transparency($this->im);		
		}
	}
	
	function handle_transparency(&$image) {
		if ( ($this->im_info[2] == IMAGETYPE_GIF) || ($this->im_info[2] == IMAGETYPE_PNG) ) {
            $trnprt_indx = imagecolortransparent($image, imagecolorallocate($image,255,255,255));

            // If we have a specific transparent color
            if ($trnprt_indx >= 0) {
  
                // Get the original image's transparent color's RGB values
                $trnprt_color    = imagecolorsforindex($image, $trnprt_indx);
  
                // Allocate the same color in the new image resource
                $trnprt_indx    = imagecolorallocate($image, $trnprt_color['red'], $trnprt_color['green'], $trnprt_color['blue']);
  
                // Completely fill the background of the new image with allocated color.
                imagefill($image, 0, 0, $trnprt_indx);
  
                // Set the background color for new image to transparent
                imagecolortransparent($image, $trnprt_indx);
  
           
            }
            // Always make a transparent background color for PNGs that don't have one allocated already
            elseif ($this->im_info[2] == IMAGETYPE_PNG) {
  
                // Turn off transparency blending (temporarily)
                imagealphablending($image, false);
  
                // Create a new transparent color for image
                $color = imagecolorallocatealpha($image, 0, 0, 0, 127);
  
                // Completely fill the background of the new image with allocated color.
                imagefill($image, 0, 0, $color);
  
                // Restore transparency blending
                imagesavealpha($image, true);
            }
        }
        
        return $image;
	}
	
	function writejpeg($file, $quality) {
	    imagejpeg($this->resized_im, $file, $quality);
	}
}
?>