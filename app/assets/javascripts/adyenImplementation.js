const clientKey = document.getElementById("clientKey").innerHTML;
const type = document.getElementById("type").innerHTML;
const country = document.getElementById("country").innerHTML;
const currency = document.getElementById("currency").innerHTML;
const amountValue = document.getElementById("amount").innerHTML;
const recurring = document.getElementById("recurring").innerHTML;

const translations = {
    "fi-FI": {
        "creditCard.holderName.placeholder": "Matti Meikäläinen",
        "creditCard.cvcField.title": "CVV/CVC-koodi",
        "continueTo": "Jatka maksutavalla",
        "paymentMethodsConfiguration.card": "Korttimaksu",
        "paymentMethodsConfiguration.ebanking_FI": "Verkkopankki"
    }
};

async function initCheckout() {
    try {
        const paymentMethodsResponse = await callServer("/api/getPaymentMethods", {
            country: country,
            locale: navigator.language
        });
        const configuration = {
            paymentMethodsResponse: paymentMethodsResponse,
            clientKey,
            locale: navigator.language,
            environment: "test",
            showPayButton: true,
            translations: translations,
            allowPaymentMethods: [
                'scheme',
                'ebanking_FI',
                //'klarna',
                //'klarna_account',
                'trustly',
                'paysafecard',
                'paywithgoogle'
            ],
            paymentMethodsConfiguration: {
                card: {
                    hasHolderName: true,
                    holderNameRequired: true,
                    enableStoreDetails: true,
                    billingAddressRequired: true, // Required to be true for 3DS2
                    name: translations[navigator.language]["paymentMethodsConfiguration.card"],
                    amount: {
                        value: amountValue,
                        currency: currency,
                    }
                },
                ebanking_FI: {
                    name: translations[navigator.language]["paymentMethodsConfiguration.ebanking_FI"],
                    amount: {
                        value: amountValue,
                        currency: currency,
                    },
                },
                trustly: {
                    amount: {
                        value: amountValue,
                        currency: currency,
                    }
                },
                paysafecard: {
                    amount: {
                        value: amountValue,
                        currency: currency,
                    }
                },
                paywithgoogle: {
                    amount: {
                        value: amountValue,
                        currency: currency,
                    }
                }
            },
            onSubmit: (state, component) => {
                if (state.isValid) {
                    handleSubmission(state, component, "/api/initiatePayment");
                }
            },
            onAdditionalDetails: (state, component) => {
                handleSubmission(state, component, "/api/submitAdditionalDetails");
            },
        };

        const checkout = new AdyenCheckout(configuration);
        checkout.create(type).mount(document.getElementById(type));
    } catch (error) {
        console.error(error);
        alert("Error occurred. Look at console for details");
    }
}

// Event handlers called when the shopper selects the pay button,
// or when additional information is required to complete the payment
async function handleSubmission(state, component, url) {
    try {
        const res = await callServer(url, state.data);
        handleServerResponse(res, component);
    } catch (error) {
        console.error(error);
        alert("Error occurred. Look at console for details");
    }
}

// Calls your server endpoints
async function callServer(url, data) {
    const res = await fetch(url, {
        method: "POST",
        body: data ? JSON.stringify(data) : "",
        headers: {
            "Content-Type": "application/json",
        },
    });

    return await res.json();
}

// Handles responses sent from your server to the client
function handleServerResponse(res, component) {
    if (res.action) {
        component.handleAction(res.action);
    } else {
        switch (res.resultCode) {
            case "Authorised":
                window.location.href = "/result/success";
                break;
            case "Pending":
            case "Received":
                window.location.href = "/result/pending";
                break;
            case "Refused":
                window.location.href = "/result/failed";
                break;
            default:
                window.location.href = "/result/error";
                break;
        }
    }
}

initCheckout();
