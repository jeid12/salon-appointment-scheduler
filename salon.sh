#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"


MAIN_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id")
  
  if [[ -z $SERVICES ]]
  then
    echo "Sorry, there is no service available"
  fi

  echo "$SERVICES" | while read SERVICE_ID BAR NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  read SERVICE_ID_SELECTED
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  fi

  REQ_SERVICE_RESULT=$($PSQL "SELECT service_id FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  if [[ -z $REQ_SERVICE_RESULT ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    REQ_SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED") 
    echo "What's your phone number?"
    read CUSTOMER_PHONE

    # find customer with phone number
    CUSTOMER=$($PSQL "SELECT * FROM customers WHERE phone='$CUSTOMER_PHONE'")

    # if not found 
    if [[ -z $CUSTOMER ]]
    then
      # ask customer name
      echo "I don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME

      # creating new customer
      NEW_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")

    fi
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

    # ask time
    echo "What time would you like your cut, $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')."
    read SERVICE_TIME

    # if no time input
    if [[ -z $SERVICE_TIME ]]
    then
      MAIN_MENU "Wrong Time Input"
    fi

    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
    NEW_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

    if [[ $APPOINTMENT_RESULT=='INSERT 0 1' ]]
    then
      echo "I have put you down for a $(echo $REQ_SERVICE_NAME | sed -E 's/^ *| *$//g') at $(echo $SERVICE_TIME | sed -E 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')."
    else
      echo "Unexpected error has occurred."
    fi
  fi
}

MAIN_MENU
