//
//  HospitalPickerViewController.swift
//  HastaneNavigasyonu
//
//  Created by Mehmet Akdeniz on 4.05.2023.
//

import UIKit

class HospitalPickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timeTextField: UITextField!
    
    var selectedHospital: Hospital?
    var selectedDate: Date?
    var selectedTime: String?
    var hospitals: [Hospital] = []
    
    var completionHandler: ((_ selectedHospital: Hospital?, _ selectedDate: Date?, _ selectedTime: String?) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        if hospitals.isEmpty {
            print("Hospitals array is empty")
        } else {
            print("Hospitals array has \(hospitals.count) items")
        }
    }
    
    // MARK: UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return hospitals.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return hospitals[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedHospital = hospitals[row]
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        let selectedIndex = pickerView.selectedRow(inComponent: 0)
        selectedHospital = hospitals[selectedIndex]
        selectedDate = datePicker.date
        selectedTime = timeTextField.text
        
        completionHandler?(selectedHospital, selectedDate, selectedTime)
        dismiss(animated: true, completion: nil)
    }
}
