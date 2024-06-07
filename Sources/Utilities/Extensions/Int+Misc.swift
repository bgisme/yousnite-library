extension Int {
    var countDigits: Int {
        // if number is zero, return count of 1
        guard self > 0 else { return 1 }
        // make storage variable
        var n = self
        // initialize count
        var count = 0
        // while number not zero
        while (n > 0){
            // remove digit from right
            n = n / 10
            // update count
            count += 1
        }
        return count
    }
}
