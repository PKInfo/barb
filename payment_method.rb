def create_payment_token_logic
	create_customer_token_logic

	if @customer_token_ready == true
		find_payment_method

		if @payment_method_found == true && @has_payment_token == false
			@skip_find_payment_method = true # This prevents the find routine from hitting the database again (to speed the process up and make it less db intensive).
			create_payment_token

		elsif @payment_method_found == true && @has_payment_token == true
			@statusCode = 220
			@statusMessage = "[ERROR] PaymentTokenAlreadyExists"
			log_result_to_console
		end
	end

	set_response
end

def create_payment_token
	unless @skip_find_directory == true
		find_directory
	end

	unless @skip_find_payment_method == true
		find_payment_method
	end

	if @create_payment_token_requirements_met == true
		request = CreateCustomerPaymentProfileRequest.new
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirst
		profile.billTo.lastName = @namelast
		request.customerProfileId = @customer_token
		request.paymentProfile = profile

		@theResponse = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if @theResponse.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@payment_token = @theResponse.customerPaymentProfileId
			@has_payment_token = true
			@statusCode = 200
			@statusMessage = "[OK] PaymentTokenCreated"
			log_result_to_console
		else
			@responseKind = "ERROR"
			@responseCode = @theResponse.messages.messages[0].code
			@responseError = @theResponse.messages.messages[0].text
			@statusCode = 210
			@statusMessage = "[ERROR] PaymentTokenNotCreated"
			log_result_to_console
		end
		
		save_payment_method
		create_payment_processor_log
		set_response
	end
end

def create_payment_token_requirements_met
	if @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == false
		@create_payment_token_requirements_met = true
		@save_payment_method = "Update"
	elsif @directory_found == true && @has_customer_token == true && @payment_method_to_be_created == true
		@create_payment_token_requirements_met = true
		@save_payment_method = "Create"
	else
		@create_payment_token_requirements_met = false
	end
end

def delete_payment_token
	unless @skip_find_directory == true
		find_directory
	end

	unless @skip_find_payment_method == true
		find_payment_method
	end

	if @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == true
		request = DeleteCustomerPaymentProfileRequest.new
		request.customerProfileId = @customer_token
		request.customerPaymentProfileId = @payment_token

		response = transaction.delete_customer_payment_profile(request)

		# The transaction has a response.
		if response.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@statusCode = 200
			@statusMessage = "[OK] PaymentTokenDeleted"
			log_result_to_console
		else
			@responseKind = "ERROR"
			@responseCode = response.messages.messages[0].code
			@responseError = response.messages.messages[0].text
			@statusCode = 210
			@statusMessage = "[ERROR] PaymentTokenNotDeleted"
			log_result_to_console
		end

		update_payment_method_after_payment_token_is_deleted
		create_payment_processor_log
		set_response
	end
end

def find_payment_method
	if @database == "BC" || @database == "CS"
		@payment_method = DATAPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)
	elsif @database == "PTD"
		@payment_method = PTDPaymentMethod.find(:__kP_PaymentMethod => @payment_method_id)
	end

	if @payment_method[0] != nil
		@payment_method_found = true
		@payment_method = @payment_method[0] # Load the record from the first position of the array.
		load_payment_method
	else
		@payment_method_found = false
		@statusCode = 300
		@statusMessage = "[ERROR] PaymentMethodRecordNotFound"
		set_response
		log_result_to_console
	end
end

def load_payment_method_by_batch
	@namefirst = @payment_method["Name_First"]
	@namelast = @payment_method["Name_Last"]
	@customer_token = @payment_method["T55_DIRECTORY::Token_Profile_ID"]
	@payment_token = @payment_method["Token_Payment_ID"]
	@cardnumber = @payment_method["CreditCard_Number"]
	@carddate = @payment_method["MMYY"]
	@cardcvv = @payment_method["CVV"]
	@address = @payment_method["Address_Address"]
	@city = @payment_method["Address_City"]
	@state = @payment_method["Address_State"]
	@zip = @payment_method["Address_Zip"]

	check_customer_token
	check_payment_token
end

def load_payment_method
	@namefirst = @payment_method["Name_First"]
	@namelast = @payment_method["Name_Last"]
	@merchant_payment_method = @payment_method["zzF_Merchant"] # Not currently being used.
	@payment_token = @payment_method["Token_Payment_ID"]
	@address = @payment_method["Address_Address"]
	@city = @payment_method["Address_City"]
	@state = @payment_method["Address_State"]
	@zip = @payment_method["Address_Zip"]

	check_payment_token
end

def save_payment_method
	if @save_payment_method == "Update"
		update_payment_method
	elsif @save_payment_method == "Create"
		create_payment_method
		update_payment_method
	end
end

def create_payment_method
	if @target_database == "DATA"
		@payment_method = DATAPaymentMethod.new
	elsif @target_database == "PTD"
		@payment_method = PTDPaymentMethod.new
	end

	@payment_method[:_kF_Directory] = @directory_id
	@payment_method[:Name_First] = @namefirst
	@payment_method[:Name_Last] = @namelast
	@payment_method[:CreditCard] = @cardnumber
	@payment_method[:MMYY] = @carddate
	@payment_method[:CVV] = @cardcvv

	# I am purposely NOT saving the record here. Instead, it'll be saved in the update_payment_token method.
end

def update_payment_method
	if @responseKind == "OK"
		@payment_method[:Token_Payment_ID] = @payment_token
		@payment_method[:zzF_Merchant] = @merchant
		@payment_method[:zzF_Status] = "Active"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @theResponse
		@payment_method[:zzPP_Response_Code] = @responseCode
		@payment_method[:zzPP_Response_Error] = @responseError
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method.save
end

def update_payment_method_after_payment_token_is_deleted
	if @responseKind == "OK"
		@payment_method[:Token_Payment_ID] = ""
		@payment_method[:zzF_Status] = "Deleted"
		@payment_method[:zzF_Type] = "Token"
	else
		@payment_method[:zzPP_Response] = @theResponse
		@payment_method[:zzPP_Response_Code] = @responseCode
		@payment_method[:zzPP_Response_Error] = @responseError
		@payment_method[:zzF_Status] = "Inactive"
		@payment_method[:zzF_Type] = "Error"
	end

	@payment_method.save
end

def update_payment_token
	find_directory
	find_payment_method

	if @directory_found == true && @has_customer_token == true && @payment_method_found == true && @has_payment_token == true
		retrieve_payment_token

		if @payment_token_retrieved == true
			request = UpdateCustomerPaymentProfileRequest.new

			# Set the @carddate = 'XXXX' and @cardcvv = nil if the user didn't enter any values.
			mask_card_date
			nil_card_cvv

			# The credit card number should not be updated per Ashley's decision. Hence the use of the @masked_card_number variable.
			creditcard = CreditCardType.new(@masked_card_number,@carddate,@cardcvv)

			payment = PaymentType.new(creditcard)
			profile = CustomerPaymentProfileExType.new(nil,nil,payment,nil,nil)
			if @update_card_address == true
				profile.billTo = CustomerAddressType.new
				profile.billTo.firstName = @namefirst
				profile.billTo.lastName = @namelast
				profile.billTo.address = @address
				profile.billTo.city = @city
				profile.billTo.state = @state
				profile.billTo.zip = @zip
			end
			request.paymentProfile = profile
			request.customerProfileId = @customer_token
			profile.customerPaymentProfileId = @payment_token

			# PASS the transaction request and CAPTURE the transaction response.
			@theResponse = transaction.update_customer_payment_profile(request)

			if @theResponse.messages.resultCode == MessageTypeEnum::Ok
				@payment_token_updated = true
				@responseKind = "OK"

				@statusCode = 200
				@statusMessage = "[OK] PaymentTokenUpdated"
				log_result_to_console
			else
				@payment_token_updated = false
				@responseKind = "ERROR"
				@responseCode = @theResponse.messages.messages[0].code
				@responseError = @theResponse.messages.messages[0].text
				@statusCode = 210
				@statusMessage = "[ERROR] PaymentTokenNotUpdated"
				log_result_to_console
			end

			create_payment_processor_log
		end
				
	else
		@statusCode = 230
		@statusMessage = "[ERROR] PaymentTokenCouldNotBeUpdated"
		log_result_to_console
	end

	set_response
	clear_response
end

def retrieve_payment_token
	request = GetCustomerPaymentProfileRequest.new
	request.customerProfileId = @customer_token
	request.customerPaymentProfileId = @payment_token

	@theResponse = transaction.get_customer_payment_profile(request)

	if @theResponse.messages.resultCode == MessageTypeEnum::Ok
		@payment_token_retrieved = true
		@responseKind = "OK"
		@masked_card_number = @theResponse.paymentProfile.payment.creditCard.cardNumber
	else
		@payment_token_retrieved = false
		@responseKind = "ERROR"
		@responseCode = @theResponse.messages.messages[0].code
		@responseError = @theResponse.messages.messages[0].text
		@statusCode = 240
		@statusMessage = "[ERROR] PaymentTokenCouldNotBeRetrieved"
		log_result_to_console
	end
end

def batch_tokenize_payment_methods
	find_payment_methods_to_tokenize_by_batch

	# This is used to mark the record's Date Processed.
	@today = Time.new

	# This outputs the batch id. It's used to display acts as the header or beginning of the process
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[PAYMENT TOKINIZATION PROCESS]"
	puts "[BATCH] #{@batch}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"

	@payment_methods.each do |pm|
		@payment_method = pm
		# These "steps" are for clarity sake.
		# Later, these objects could be saved somewhere to log the steps of each batch when it's run.
		@step1 = load_payment_method_by_batch
		@step2 = create_payment_token_by_batch
		@step3 = log_result_to_console_for_batch_tokenization

		# This prevents the record from being updated if a token wasn't created/attempted.
		if @flag_update_payment_method == true
			@step4 = update_payment_method
		end

		@step5 = clear_response
		@step6 = clear_batch_tokenization_variables
	end

end

def find_payment_methods_to_tokenize_by_batch
	if @database == "BC"
		@payment_methods = DATAPaymentMethod.find(:zzF_Batch => @batch)
	elsif @database == "PTD"
		@payment_methods = PTDPaymentMethod.find(:zzF_Batch => @batch)
	end
end

def create_payment_token_by_batch
	if @has_customer_token == true && @has_payment_token == false
		request = CreateCustomerPaymentProfileRequest.new
		creditcard = CreditCardType.new(@cardnumber,@carddate,@cardcvv)
		payment = PaymentType.new(creditcard)
		profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)
		profile.billTo = CustomerAddressType.new
		profile.billTo.firstName = @namefirst
		profile.billTo.lastName = @namelast
		request.customerProfileId = @customer_token
		request.paymentProfile = profile

		@theResponse = transaction.create_customer_payment_profile(request)

		# The transaction has a response.
		if @theResponse.messages.resultCode == MessageTypeEnum::Ok
			@responseKind = "OK"
			@payment_token = @theResponse.customerPaymentProfileId
			@statusCode = 200
			@statusMessage = "[OK] PaymentTokenCreated"
		else
			@responseKind = "ERROR"
			@responseCode = @theResponse.messages.messages[0].code
			@responseError = @theResponse.messages.messages[0].text
			@statusCode = 210
			@statusMessage = "[ERROR] PaymentTokenNotCreated"
		end

		@flag_update_payment_method = true

	else
		@flag_update_payment_method = false

	end
end
