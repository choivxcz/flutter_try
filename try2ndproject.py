def info():
    data = []
    while True:
        riskScore = 0
        houseID = input("Enter your house ID: ")
        houseType = input("Enter your house type (Nipa, Concrete, Wood, Concrete):")
        eldercount = int(input("Enter how many elder/s are in your house: "))
        childrencount = int(input("Enter how many child are there in your house: "))
        
        if houseType == "Nipa":
            riskScore += 10
        elif houseType == "Concrete":
            riskScore +=20
        elif houseType == "Wood":
            riskScore += 30  
        riskScore += eldercount * 10
        riskScore += childrencount * 20
        
        data.append({
            "House ID": houseID,
            "House Type": houseType,
            "Elder Count": eldercount,
            "Children Count": childrencount,
            "Risk Score": riskScore, 
            })
        # Ask if user wants to continue
        cont = input("Do you want to add another household? (yes/no): ").strip().lower()
        if cont != "yes":
            break  
        
    return data

houseData = info()
print(houseData)
    