import XCTest
@testable import Apio

final class ApioTests: XCTestCase
{
    func testGenerate()
    {
        
        let apiCreated = generate(api: createAPI(), target: "TestGoDaddy", authorizationType: .header(authorizationLabel: "sso-key"))
        
        XCTAssertTrue(apiCreated)
    }
    
    func createAPI() -> API
    {
        let errorResult = ResultType(name: "Error",
                                            fields: [("id", .string),
                                                     ("message", .string)])
        
        let purchaseDomainResult = ResultType(name: "Purchase", fields: [("currency", .string),
                                                                                ("itemCount", .int32),
                                                                                ("orderId", .int32),
                                                                                ("total", .float)
                                                                               ])
        
        let domainsDocumentationURL = "https://developer.godaddy.com/doc/endpoint/domains"
        
        // Purchase Domain Function
        let purchaseDomainDocumentationURL = "https://developer.godaddy.com/doc/endpoint/domains#/v1/purchase"
        
        // Domain
        let domainProperty = StructureProperty(name: "domain",
                                               valueType: .string)
        // Consent
        let agreementKeysProperty = StructureProperty(name: "agreementKeys",
                                                      valueType: .array(.string),
                                                      description: "Unique identifiers of the legal agreements to which the end-user has agreed, as returned from the/domains/agreements endpoint")
        let agreedByProperty = StructureProperty(name: "agreedBy",
                                                 valueType: .string,
                                                 description: "Originating client IP address of the end-user's computer when they consented to these legal agreements")
        let agreedAtProperty = StructureProperty(name: "agreedAt",
                                                 valueType: .string,
                                                 description: "Timestamp in iso-datetime format indicating when the end-user consented to these legal agreements. ")
        let consentType = StructureType(name: "Consent",
                                        fields: [agreementKeysProperty,
                                                  agreedByProperty,
                                                  agreedAtProperty])
        let consentProperty = StructureProperty(name: "consent",
                                                valueType: .structure(consentType))
        
        
        // Contact
        let firstNameProperty = StructureProperty(name: "nameFirst",
                                                  valueType: .string,
                                                  description: "No spaces, max length is 30")
        let lastNameProperty = StructureProperty(name: "nameLast",
                                                 valueType: .string,
                                                 description: "No spaces, max length is 30")
        let emailProperty = StructureProperty(name: "email",
                                              valueType: .string,
                                              description: "No spaces, max length is 80")
        let phoneProperty = StructureProperty(name: "phone",
                                              valueType: .string,
                                              description: "No spaces, max length is 17")
        
        let address1Property = StructureProperty(name: "address1",
                                                 valueType: .string,
                                                 description: "Max length is 41")
        let cityProperty = StructureProperty(name: "city",
                                             valueType: .string,
                                             description: "Max length is 30")
        let postalCodeProperty = StructureProperty(name: "postalCode",
                                                   valueType: .string,
                                                   description: "Postal or zip code. Max length is 10")
        let countryProperty = StructureProperty(name: "country",
                                                valueType: .string,
                                                description: "Two-letter ISO country code to be used as a hint for target region http://www.iso.org/iso/country_codes.htm")
        
        // addressType
        let addressType = StructureType(name: "Address",
                                        fields: [address1Property,
                                                 cityProperty,
                                                 postalCodeProperty,
                                                 countryProperty])
        
        let addressMailingProperty = StructureProperty(name: "addressMailing",
                                                       valueType: .structure(addressType))
        
        // contactType
        let contactType = StructureType(name: "Contact", fields: [firstNameProperty,
                                                                  lastNameProperty,
                                                                  emailProperty,
                                                                  phoneProperty,
                                                                  addressMailingProperty])
        
        let contactAdminProperty = StructureProperty(name: "contactAdmin",
                                                     valueType: .structure(contactType))
        let contactBillingProperty = StructureProperty(name: "contactBilling",
                                                       valueType: .structure(contactType))
        let contactRegistrantProperty = StructureProperty(name: "contactRegistrant",
                                                          valueType: .structure(contactType))
        let contactTechProperty = StructureProperty(name: "contactTech",
                                                    valueType: .structure(contactType))
        
        // purchaseRequestType
        let purchaseRequestType = StructureType(name: "PurchaseRequest",
                                                         fields: [domainProperty,
                                                                  consentProperty,
                                                                  contactAdminProperty,
                                                                  contactBillingProperty,
                                                                  contactRegistrantProperty,
                                                                  contactTechProperty])
        
        
        let purchaseDomainParameters = [Parameter(name: "purchaseRequest",
                                                  description: "An instance document expected to match the JSON schema returned by ./schema/{tld}",
                                                  type: .structure(purchaseRequestType),
                                                  optional: false)]
        let purchaseDomainFunction = Function(name: "purchase",
                                              documentationURL: purchaseDomainDocumentationURL,
                                              resultType: purchaseDomainResult,
                                              parameters: purchaseDomainParameters,
                                              subDirectory: "purchase")
        
        // Domains Endpoint
        let domainsEndpoint = Endpoint(name: "Domains",
                                       documentationURL: domainsDocumentationURL,
                                       functions: [ purchaseDomainFunction],
                                       errorResultType: errorResult)
        
        return API(name: "TestAPI",
                   url: "https://api.digitalocean.com/v2",
                   documentationURL: "https://docs.digitalocean.com/reference/api/api-reference/",
                   resultTypes: [],
                   structTypes: [contactType, purchaseRequestType, addressType, consentType],
                   endpoints: [domainsEndpoint])
    }
}
