include AuthorizeNet::API

def initiate_transaction
	config = YAML.load_file(File.dirname(__FILE__) + "/../config/credentials.yml")
	transaction = Transaction.new(config['api_login_id'], config['api_transaction_key'], :gateway => :production)
end

def capture_response
	response = initiate_transaction.create_transaction(request)

	if response.transactionResponse != nil

		# Capture the response variables for all transactions.
		@response = response
		# @avsCode = response.transactionResponse.avsResultCode
		# @cvvCode = response.transactionResponse.cvvResultCode

		# The transaction has a response.
		if response.messages.resultCode == MessageTypeEnum::Ok
			@resultCode = "OK"

			# CAPTURE the transaction details.
			@transactionID = response.transactionResponse.transId
			@transactionResponseCode = response.transactionResponse.responseCode

			if @transactionResponseCode == "1"
				@responseKind = "Approved"
				@authorizationCode = response.transactionResponse.authCode
				@responseCode = response.messages.messages[0].code
				@responseMessage = response.messages.messages[0].text

			elsif @transactionResponseCode == "2"
				@responseKind = "Declined"
				@responseCode = response.transactionResponse.errors.errors[0].errorCode
				@responseError = response.transactionResponse.errors.errors[0].errorText

			elsif @transactionResponseCode == "3"
				@responseKind = "Error"
				@responseCode = response.transactionResponse.errors.errors[0].errorCode
				@responseError = response.transactionResponse.errors.errors[0].errorText

			elsif @transactionResponseCode == "4"
				@responseKind = "HeldforReview"
				@responseCode = response.transactionResponse.errors.errors[0].errorCode
				@responseError = response.transactionResponse.errors.errors[0].errorText
			end

		# A transactional ERROR occurred.
		elsif response.messages.resultCode == MessageTypeEnum::Error
			@resultCode = "ERROR"

			@responseKind = "TransactionError"
			@responseCode = response.transactionResponse.errors.errors[0].errorCode
			@responseError = response.transactionResponse.errors.errors[0].errorText
		end

	# A transactional FAILURE occurred. [NIL]
	else
		@responseKind = "TransactionFailure"
		@responseError = "A transactional FAILURE occurred."
	end
end
