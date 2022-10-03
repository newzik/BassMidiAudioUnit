import Foundation
import AVFoundation

extension BassMidiAudioUnit {

    private func paramValue(address: AUParameterAddress) -> AUValue? {
        parameterTree?.parameter(withAddress: address)?.value
    }

    private func setParam(value: AUValue, address: AUParameterAddress) {
        parameterTree?.parameter(withAddress: address)?.value = value
    }

}
