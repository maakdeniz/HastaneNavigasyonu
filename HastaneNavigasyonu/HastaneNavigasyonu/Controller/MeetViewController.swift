//
//  MeetViewController.swift
//  HastaneNavigasyonu
//
//  Created by Mehmet Akdeniz on 4.05.2023.
//
import CoreData
import UIKit



struct Appointment {
    let hospital: String
    let date: Date
    let time: String
    
    init(hospital: String, date: Date, time: String) {
        self.hospital = hospital
        self.date = date
        self.time = time
    }
    
    init(managedObject: NSManagedObject) {
        self.hospital = managedObject.value(forKey: "hospital") as? String ?? ""
        self.date = managedObject.value(forKey: "date") as? Date ?? Date()
        self.time = managedObject.value(forKey: "time") as? String ?? ""
    }
}


class AppointmentTableViewCell: UITableViewCell {
    @IBOutlet weak var hospitalLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
}

class MeetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var tableView: UITableView!
    var appointments: [Appointment] = []
    var hospitals: [Hospital] = []
    var hospitalNames: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let loadedHospitals = loadHospitals() {
            self.hospitals = loadedHospitals
            self.hospitalNames = loadedHospitals.map { $0.name }
        }
        tableView.delegate = self
        tableView.dataSource = self
        fetchAppointments()
    }
    
    func loadHospitals() -> [Hospital]? {
        guard let url = Bundle.main.url(forResource: "hospitals", withExtension: "json") else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let hospitals = try decoder.decode([Hospital].self, from: data)
            return hospitals
        } catch {
            print("Error loading hospitals: \(error)")
            return nil
        }
    }
    
    //MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appointments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentCell", for: indexPath) as? AppointmentTableViewCell else {
            fatalError("The dequeued cell is not an instance of AppointmentTableViewCell.")
        }
        let appointment = appointments[indexPath.row]
        cell.hospitalLabel.text = appointment.hospital
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        cell.dateLabel.text = dateFormatter.string(from: appointment.date)
        
        cell.timeLabel.text = appointment.time
        
        return cell
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
    
    func showHospitalPickerViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let hospitalPickerController = storyboard.instantiateViewController(withIdentifier: "HospitalPickerViewController") as! HospitalPickerViewController
        hospitalPickerController.modalPresentationStyle = .overCurrentContext
        hospitalPickerController.modalPresentationStyle = .fullScreen
        hospitalPickerController.modalTransitionStyle = .crossDissolve
        
        hospitalPickerController.hospitals = hospitals 
        
        hospitalPickerController.completionHandler = { [weak self] selectedHospital, selectedDate, selectedTime in
            guard let self = self, let hospital = selectedHospital, let date = selectedDate, let time = selectedTime else { return }
            let appointment = Appointment(hospital: hospital.name, date: date, time: time)
            self.saveAppointment(appointment: appointment)
        }
        
        present(hospitalPickerController, animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        showHospitalPickerViewController()
    }
}



extension MeetViewController {
    func fetchAppointments() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppointmentEntity")
        
        do {
            let result = try context.fetch(fetchRequest)
            appointments = result.map { Appointment(managedObject: $0) }
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch appointments. \(error), \(error.userInfo)")
        }
    }
    
    func saveAppointment(appointment: Appointment) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "AppointmentEntity", in: context)!
        let managedObject = NSManagedObject(entity: entity, insertInto: context)
        
        managedObject.setValue(appointment.hospital, forKey: "hospital")
        managedObject.setValue(appointment.date, forKey: "date")
        managedObject.setValue(appointment.time, forKey: "time")
        
        do {
            try context.save()
            appointments.append(appointment)
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not save appointment. \(error), \(error.userInfo)")
        }
    }
}

