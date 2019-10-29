def check_customer_token
	if @customer_token != nil
		@has_customer_token = true
	else
		@has_customer_token = false
	end
end

def check_payment_token
	if @payment_token != nil
		@has_payment_token = true
	else
		@has_payment_token = false
	end
end

# This either loads the merchant value from the directory object or sets it to the default per application.
def load_assigned_merchant_or_set_default
	if @merchant_directory == "BAR" || @merchant_directory == "PTD"
		@merchant = @merchant_directory
	elsif @database == "BC" || @database == "CS" || @database == "DATA"
		@merchant = "BAR"
	elsif @database == "PTD"
		@merchant = "PTD"
	else
		@merchant = "MISSING"
	end
end

# This ensures that the directory and payment method records have been assigned to a merchant.
# It also clears the @merchant variable if they don't match.
# Without a @metchant variable, the transaction_ready method will prevent the tranaction from proceeding.
def check_directory_and_payment_method_merchants
	if @merchant_payment_method == @merchant_directory && @merchant_directory != nil && @merchant_payment_method != nil
		@merchant = @merchant_directory
	elsif @merchant_payment_method != @merchant_directory
		@merchant = "MISMATCH"
	else
		@merchant = "MISSING"
	end
end

# This determines whether or not to process this payment or not.
def process_or_skip

	# Check if this payment is by ids or card.
	card_or_token

	if @card_or_tokens == "tokens" || @card_or_tokens == "card"
		@process_or_skip = "Process"
		process_payment
	else
		@process_or_skip = "Skip"
	end
end

# This determines if this transaction should be processed using Authorize IDs or a CC.
def card_or_token

	# If this record has (Authorize.net) IDs, validate them.
	if @customer_token && @payment_token

		# Validate the IDs.
		validate_tokens

		if @valid_tokens == true
			@card_or_tokens = "tokens"
		else
			@card_or_tokens = "error"
		end

	# If this record has credit card values, use them.
	else
		@card_or_tokens = "card"
	end
end

# SET the GL Codes.
def set_gl_codes
	if @database == "BC"
		bc_gl_code
	elsif @database == "CS"
		cs_gl_code
	elsif @database == "DL"
		dl_gl_code
	elsif @database == "PTD"
		ptd_gl_code
	end
end

# This GL Code is referenced in the process_payment method.
# This GL Code is used to categorize tranasactions.
def ptd_gl_code

	date = Time.now
	month = date.month
	year = date.year
	nextyear = year + 1

	# From Angela on Slack on 09/26/19
	# PTD19 coding should stay the same.
	# PTD20 should be 242.  And yes, 242 is correct until December 31, On January 1 it should then go to 241.  The new codes are a change in the Finance process, that I didn't have changed halfway through 2019, and am now using this opportunity to change/correct it.  
	# If it is too much to change/fix, October 1 is a few days away and I can just continue running a daily analysis and break out the '19 from the '20.  But I do need the actual codes to change to 241 and 242.

	# October is when the GL Code swithces to 424.
	month_ptd = 10

	# New code from 10/29/19
	if (month >= month_ptd)
		@gl_code = "242"
		@invoice = "PTD#{short_year(nextyear)}"
	else
		@gl_code = "241"
		@invoice = "PTD#{short_year(year)}"
	end

	# Old code from before 10/29/19
	# if (month >= month_ptd)
	# 	@gl_code = "424"
	# 	@invoice = "PTD#{short_year(nextyear)}"
	# else
	# 	@gl_code = "423"
	# 	@invoice = "PTD#{short_year(year)}"
	# end

end

def bc_gl_code
	date = Time.now
	year = date.year

	if @gl_override_flag == true && @gl_override_code != nil
		@gl_code = @gl_override_code
	elsif @event_year.to_i > year # If the event is next year.
		@gl_code = "421"
	else
		@gl_code = "422"
	end
	
	puts "[EVENT_YEAR] #{@event_year}"
	puts "[EVENT_ABBR] #{@event_abbr}"

	@invoice = "BCOMP#{@event_abbr}#{short_year(@event_year)}"
end

def cs_gl_code
	date = Time.now
	year = date.year

	unless @class_date.nil?
		if @today < @class_date
			@gl_code = "403"
		elsif @today < @class_date + 7
			@gl_code = "402"
		else
			@gl_code = "401"
		end
	else
		@gl_code = "401"
	end

	# @invoice is set in the load_payment_date method for CS records.
end

def dl_gl_code
	unless @program.nil?
		if @program == "BC"
			bc_gl_code
		# elsif @program == "CS"
			# cs_gl_code # Not yet developed. Not sure how the @invoice variable would be set.
		elsif @program == "PTD"
			ptd_gl_code
		end
	else
		@gl_code = "99"
		@invoice = "Program Missing"
	end
end

def short_year (yr)
	yr.to_s.split(//).last(2).join("").to_s
end

def set_response
	@status = @status_code
	@body = @status_message
end

def clear_response
	@authorize_response = nil
	@authorize_response_kind = nil
	@authorize_response_code = nil
	@authorize_response_message = nil
	@result = nil
	@avs_code = nil
	@cvv_code = nil
	@transaction_id = nil
	@authorization_code = nil
	@status_code = nil
	@status_message = nil
end

def to_boolean (string)
	unless string.nil?
		string.downcase == 'true' || string == '1'
	else
		false	
	end
end

def mask_card_date
	unless @update_card_date == true
		@card_mmyy = 'XXXX'
	end
end

def nil_card_cvv
	unless @update_card_cvv == true
		@card_cvv = nil
	end
end

def log_result_to_console
	puts "\n\n\n\n\n"
	puts "----------------------------------------"
	puts "[DATABASE] #{@database}"
	puts "[DIRECTORY] #{@directory_id}"
	puts "[LEAD] #{@lead_id}"
	puts "[GUEST] #{@guest_id}"
	puts "[PAYMENTMETHOD] #{@payment_method_id}"
	puts "[PAYMENTDATE] #{@payment_date_id}"
	puts "[RECORD] #{@serial}"
	puts "[MERCHANT] #{@merchant}"
	puts "[CUSTOMERTOKEN] #{@customer_token}"
	puts "[PAYMENTTOKEN] #{@payment_token}"
	puts "\n"
	puts "[RESPONSE] #{@authorize_response_kind}"
	puts "[AUTHORIZATION] #{@authorization_code}"
	puts "[CODE] #{@authorize_response_code}"
	puts "[ERROR] #{@authorize_response_message}"
	puts "[P or S] #{@process_or_skip}"
	puts "\n"
	puts "[GLCODE] #{@gl_code}"
	puts "[INVOICE] #{@invoice}"
	puts "[CLASSDATE] #{@class_date}"
	puts "[PROGRAM] #{@program}"
	puts "\n"
	puts "[STATUSCODE] #{@status_code}"
	puts "[STATUSMESSAGE] #{@status_message}"
	puts "[TIMESTAMP] #{Time.now}"
	puts "----------------------------------------"
end