//
//  ImagePicker.swift
//  ImageCropFeature
//
//  Created by sohamp on 27/06/24.
//

import UIKit
import Photos

public protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
}

open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            if (type.rawValue == 1) {
                self.actionForCamera()
            } else if (type.rawValue == 0){
                self.actionForLibrary()
                }   else{
                //None
            }
        }
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
//        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
//            alertController.addAction(action)
//        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }
    
    private func actionForCamera(){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let cameraMediaType = AVMediaType.video
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
                
            switch cameraAuthorizationStatus {
            case .denied:
                print("User has denied the camera permission.")
                let alert = UIAlertController(title: "Cannot access Camera", message:"Please adjust device settings and grant access." , preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.presentationController?.present(alert, animated: true, completion: nil)
                break
            case .authorized:
                self.pickerController.modalPresentationStyle = .fullScreen
                self.pickerController.sourceType = .camera
                self.presentationController?.present(self.pickerController, animated: true)
                print("Access is granted by user")
                break
            case .restricted:
                print("User do not have access to photo album.")
                break
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                    if granted {
                        print("Granted access to \(cameraMediaType)")
                        DispatchQueue.main.async {
                            self.pickerController.modalPresentationStyle = .fullScreen
                            self.pickerController.sourceType = .camera
                            self.presentationController?.present(self.pickerController, animated: true)
                        }
                    } else {
                        print("Denied access to \(cameraMediaType)")
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Cannot access Camera", message:" User has explicitly denied this application access to camera" , preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                            self.presentationController?.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            @unknown default:
                print("Unknown default permission.")
            }
        }
    }
    
    private func actionForLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            switch photoAuthorizationStatus {
            case .authorized:
                self.pickerController.modalPresentationStyle = .fullScreen
                self.pickerController.sourceType = .photoLibrary
                self.presentationController?.present(self.pickerController, animated: true)
                print("Access is granted by user")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({
                    (newStatus) in
                    //print("status is \(newStatus)")
                    if newStatus ==  PHAuthorizationStatus.authorized {
                        DispatchQueue.main.async {
                            self.pickerController.modalPresentationStyle = .fullScreen
                            self.pickerController.sourceType = .photoLibrary
                            self.presentationController?.present(self.pickerController, animated: true)
                        }
                        //print("success")
                    }
                    if (newStatus.rawValue == 2){
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Cannot access Photo library", message:" User has explicitly denied this application access to photos data" , preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                            self.presentationController?.present(alert, animated: true, completion: nil)
                        }
                    }
                })
                print("It is not determined until now")
            case .restricted:
                print("User do not have access to photo album.")
            case .denied:
                print("User has denied the library permission.")
                let alert = UIAlertController(title: "Cannot access Photo library", message:"Please adjust device settings and grant access." , preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.presentationController?.present(alert, animated: true, completion: nil)
            case .limited:
                print("User has limited permission.")
            @unknown default:
                print("Unknown default permission.")
            }
          }
      }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
