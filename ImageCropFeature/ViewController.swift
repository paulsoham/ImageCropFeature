//
//  ViewController.swift
//  ImageCropFeature
//
//  Created by sohamp on 27/06/24.
//

import UIKit

class ViewController: UIViewController, CropViewControllerDelegate {
    var imagePicker: ImagePicker!
    private var croppingStyle = CropViewCroppingStyle.default
    private var croppedRect = CGRect.zero
    
    @IBOutlet weak var croppedImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }

    
    @IBAction func selectImage(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
}

extension ViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        if (image != nil){
            self.launchCropViewController(image: image!)
        }
    }
    
    public func launchCropViewController (image: UIImage){
        let cropController = ImageCropViewController(croppingStyle: croppingStyle, image: image)
        cropController.delegate = self
        cropController.rotateButtonsHidden = false
        cropController.rotateClockwiseButtonHidden = false
        cropController.toolbar.clampButtonHidden = false
        self.present(cropController, animated: true, completion: nil)

    }
    func cropViewController(_ cropViewController: ImageCropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: ImageCropViewController) {
        layoutImageView()
        self.croppedImageView.image = image

        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.croppedImageView.isHidden = true
        cropViewController.dismissAnimatedFrom(self, withCroppedImage: image,
                                               toView: croppedImageView,
                                               toFrame: CGRect.zero,
                                               setup: { self.layoutImageView() },
                                               completion: {
                                                    self.croppedImageView.isHidden = false
                                                })
    }
    
    public func layoutImageView() {
        guard croppedImageView.image != nil else { return }
        
        let padding: CGFloat = 20.0
        
        var viewFrame = self.view.bounds
        viewFrame.size.width -= (padding * 2.0)
        viewFrame.size.height -= ((padding * 2.0))
        
        var imageFrame = CGRect.zero
        imageFrame.size = croppedImageView.image!.size;
        
        if croppedImageView.image!.size.width > viewFrame.size.width || croppedImageView.image!.size.height > viewFrame.size.height {
            let scale = min(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height)
            imageFrame.size.width *= scale
            imageFrame.size.height *= scale
            imageFrame.origin.x = (self.view.bounds.size.width - imageFrame.size.width) * 0.5
            imageFrame.origin.y = (self.view.bounds.size.height - imageFrame.size.height) * 0.5
            croppedImageView.frame = imageFrame
        }
        else {
            self.croppedImageView.frame = imageFrame;
            self.croppedImageView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        }
    }
}
