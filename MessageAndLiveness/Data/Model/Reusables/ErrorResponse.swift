//
//  ErrorResponse.swift
// MessageAndLiveness
//
//  Created by Ewide Dev 5 on 10/12/25.
//

import Foundation

struct ErrorResponse: Codable, Error {
	let success: Bool?
	let statusCode: Int?
	let message: String?
	let errors: ErrorField?
	
	enum CodingKeys: String, CodingKey {
		case success
		case statusCode = "status_code"
		case message
		case errors
	}
}

struct ErrorField: Codable {
	// MARK: - Login Related Errors
	let email: [String]?
	let password: [String]?
	
	// MARK: - Update Profile related Errors
	let title: [String]?
	let firstName: [String]?
	let lastName: [String]?
	let preferredFirstName: [String]?
	let personalEmail: [String]?
	let dateOfBirth: [String]?
	let gender: [String]?
	let personalPhone: [String]?
	let personalPhoneCountryCode: [String]?
	let residentialAddress: [String]?
	let isAboriginalOrTorresStraitIslander: [String]?
	let emergencyContactName: [String]?
	let emergencyContactRelationship: [String]?
	let emergencyContactPhone: [String]?
	let emergencyContactEmail: [String]?
	let taxFileNumber: [String]?
	let bankAccountName: [String]?
	let bankAccountNumber: [String]?
	let bankBSB: [String]?
	let superFund: [String]?
	let superMemberNumber: [String]?
	let drivingLicenseFirstName: [String]?
	let drivingLicenseSurname: [String]?
	let drivingLicenseState: [String]?
	let drivingLicenseNumber: [String]?
	let drivingLicenseExpiryDate: [String]?
	let whiteCardNotApplicable: [String]?
	let whiteCardFullName: [String]?
	let whiteCardCardNumber: [String]?
	let whiteCardRTONumber: [String]?
	let whiteCardDateOfIssue: [String]?
	let whiteCardState: [String]?
	
	// MARK: - Update Password related Errors
	let currentPassword: [String]?
	
	// MARK: - Rename TOTP Deice
	let newName: [String]?
	
	enum CodingKeys: String, CodingKey {
		// MARK: - Login Related Errors
		case email
		case password
		
		// MARK: - Update Profile related Errors
		case title
		case firstName = "first_name"
		case lastName = "last_name"
		case preferredFirstName = "preferred_first_name"
		case personalEmail = "personal_email"
		case dateOfBirth = "date_of_birth"
		case gender
		case personalPhone = "personal_phone"
		case personalPhoneCountryCode = "personal_phone_country_code"
		case residentialAddress = "residential_address"
		case isAboriginalOrTorresStraitIslander = "is_aboriginal_or_torres_strait_islander"
		case emergencyContactName = "emergency_contact_name"
		case emergencyContactRelationship = "emergency_contact_relationship"
		case emergencyContactPhone = "emergency_contact_phone"
		case emergencyContactEmail = "emergency_contact_email"
		case taxFileNumber = "tax_file_number"
		case bankAccountName = "bank_account_name"
		case bankAccountNumber = "bank_account_number"
		case bankBSB = "bank_bsb"
		case superFund = "super_fund"
		case superMemberNumber = "super_member_number"
		case drivingLicenseFirstName = "driving_license_first_name"
		case drivingLicenseSurname = "driving_license_surname"
		case drivingLicenseState = "driving_license_state"
		case drivingLicenseNumber = "driving_license_number"
		case drivingLicenseExpiryDate = "driving_license_expiry_date"
		case whiteCardNotApplicable = "white_card_not_applicable"
		case whiteCardFullName = "white_card_full_name"
		case whiteCardCardNumber = "white_card_card_number"
		case whiteCardRTONumber = "white_card_rto_number"
		case whiteCardDateOfIssue = "white_card_date_of_issue"
		case whiteCardState = "white_card_state"
		
		// MARK: - Update Password related Errors
		case currentPassword = "current_password"
		
		// MARK: - Rename TOTP Deice
		case newName = "new_name"
	}
}
